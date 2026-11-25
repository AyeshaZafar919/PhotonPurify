import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintPanel extends StatefulWidget {
  @override
  _ComplaintPanelState createState() => _ComplaintPanelState();
}

class _ComplaintPanelState extends State<ComplaintPanel> {
  String _filter = "All";
  final TextEditingController _search = TextEditingController();

  // === Fetch Complaints Stream ===
  // If _filter == "All" we ask server to order by createdAt.
  // If filtering by status, we query by status only (no orderBy) and sort client-side.
  Stream<QuerySnapshot> getComplaints() {
    final base = FirebaseFirestore.instance.collection('complaints');
    if (_filter == "All") {
      return base.orderBy('createdAt', descending: true).snapshots();
    } else {
      return base.where('status', isEqualTo: _filter).snapshots();
    }
  }

  // === Assign Technician ===
  void assignTechnician(BuildContext context, String complaintId) async {
    final technicians = await FirebaseFirestore.instance
        .collection('users')
        .where('urole', isEqualTo: 'Technician')
        .where('ustatus', isEqualTo: 'Active')
        .get();

    showDialog(
      context: context,
      builder: (context) {
        String? selectedTechnician;
        return AlertDialog(
          title: const Text("Assign Technician"),
          content: DropdownButtonFormField<String>(
            hint: const Text("Select Technician"),
            value: selectedTechnician,
            items: technicians.docs.map((tech) {
              return DropdownMenuItem<String>(
                value: tech.id,
                child: Text(tech['uname'] ?? 'No name'),
              );
            }).toList(),
            onChanged: (value) {
              selectedTechnician = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedTechnician != null) {
                  final techDoc = technicians.docs
                      .firstWhere((doc) => doc.id == selectedTechnician);
                  await FirebaseFirestore.instance
                      .collection('complaints')
                      .doc(complaintId)
                      .update({
                    'technicianId': selectedTechnician,
                    'technicianName': techDoc['uname'],
                    'status': 'Assigned',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Assign"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // === Update Complaint Status ===
  Future<void> updateStatus(String complaintId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // === Get Stats Stream ===
  Stream<Map<String, int>> getComplaintStats() {
    return FirebaseFirestore.instance.collection('complaints').snapshots().map(
      (snapshot) {
        int today = 0,
            pending = 0,
            assigned = 0,
            inProgress = 0,
            completed = 0,
            resolved = 0;
        final now = DateTime.now();

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          if (createdAt != null &&
              createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day) {
            today++;
          }
          if (status == 'Pending') pending++;
          if (status == 'Assigned') assigned++;
          if (status == 'In Progress') inProgress++;
          if (status == 'Completed') completed++;
          if (status == 'Resolved') resolved++;
        }

        return {
          'today': today,
          'pending': pending,
          'assigned': assigned,
          'inProgress': inProgress,
          'completed': completed,
          'resolved': resolved,
        };
      },
    );
  }

  // === Reusable Stat Card ===
  Widget buildStatCard(String title, int value, Color color) {
  return Container(
    width: 110,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),

      // Glass effect
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.02),
        ],
      ),

      border: Border.all(color: Colors.white12),

      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 5,
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$value",
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  // === Helper: status -> color for list card
  Color _statusBaseColor(String status) {
  switch (status) {
    case 'Pending':
      return const Color(0xFFFFB020); // amber
    case 'Assigned':
      return const Color(0xFF6366F1); // indigo
    case 'In Progress':
      return const Color(0xFF8B5CF6); // purple
    case 'Completed':
      return const Color(0xFF14B8A6); // teal
    case 'Resolved':
      return const Color(0xFF22C55E); // green
    default:
      return const Color(0xFF94A3B8); // gray
  }
}

  // === Show details dialog
  void _showComplaintDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['description'] != null) ...[
                const Text("Description:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['description']),
                const SizedBox(height: 8),
              ],
              Text("Status: ${data['status'] ?? 'Unknown'}"),
              const SizedBox(height: 4),
              Text("Urgency: ${data['urgency'] ?? 'N/A'}"),
              const SizedBox(height: 4),
              if (data['technicianName'] != null)
                Text("Technician: ${data['technicianName']}"),
              const SizedBox(height: 8),
              Text(
                "Created At: ${((data['createdAt'] as Timestamp?)?.toDate() ?? 'N/A').toString()}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
  backgroundColor: const Color(0xFF05070F),
  body: SafeArea(
    child: SingleChildScrollView(
      child: Column(
        children: [

          // 🔥 HEADER (now scrollable)
          _modernHeader(),
          const SizedBox(height: 12),

          // 🔥 STATS (scrollable)
          StreamBuilder<Map<String, int>>(
            stream: getComplaintStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final stats = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    buildStatCard("Today", stats['today']!, Colors.blue),
                    buildStatCard("Pending", stats['pending']!, Colors.orange),
                    buildStatCard("Assigned", stats['assigned']!, Colors.purple),
                    buildStatCard("Completed", stats['completed']!, Colors.teal),
                    buildStatCard("Resolved", stats['resolved']!, Colors.green),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 🔥 SEARCH + FILTER (scrollable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 10),
                _buildFilterButton(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🔥 COMPLAINT LIST (IMPORTANT: remove Expanded)
          StreamBuilder<QuerySnapshot>(
            stream: getComplaints(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final complaintDoc = docs[index];
                  final data = complaintDoc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString();

                  return _modernComplaintCard(
                    data,
                    complaintDoc.id,
                    status,
                    _statusBaseColor(status),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
  ),
);
  }

  Widget _modernHeader() {
  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF020617), Color(0xFF0F172A)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.orangeAccent.withOpacity(0.3),
          blurRadius: 5,
        )
      ],
    ),
    child: Row(
      children: const [
        Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
        SizedBox(width: 10),
        Text(
          "COMPLAINT CONTROL CENTER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

Widget _modernComplaintCard(
  Map<String, dynamic> data,
  String id,
  String status,
  Color color,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),

      // 🔥 Gradient background (modern feel)
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.18),
          Colors.black.withOpacity(0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),

      // 🔥 Glow effect
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.35),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],

      border: Border.all(color: color.withOpacity(0.25)),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔥 TOP ROW
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.report_problem, color: color, size: 18),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                data['title'] ?? "No Title",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            _popupMenu(id, status, data),
          ],
        ),

        const SizedBox(height: 10),

        // 🔥 STATUS CHIP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 🔥 DETAILS
        Text(
          "Urgency: ${data['urgency'] ?? 'N/A'}",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

Widget _chip(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      "$label: $value",
      style: TextStyle(color: color, fontSize: 11),
    ),
  );
}

Widget _popupMenu(String id, String status, Map<String, dynamic> data) {
  return PopupMenuButton<String>(
    color: Colors.black,
    onSelected: (value) async {
      if (value == 'Assign') {
        assignTechnician(context, id);
      } else if (value == 'Resolve') {
        await updateStatus(id, 'Resolved');
      } else if (value == 'View') {
        _showComplaintDetails(data);
      }
    },
    itemBuilder: (context) {
      List<PopupMenuEntry<String>> items = [
        const PopupMenuItem(value: 'View', child: Text("View")),
      ];

      if (status == 'Pending') {
        items.add(const PopupMenuItem(value: 'Assign', child: Text("Assign")));
      }

      if (status != 'Resolved') {
        items.add(const PopupMenuItem(value: 'Resolve', child: Text("Resolve")));
      }

      return items;
    },
  );
}

Widget _buildSearchField() {
  return TextField(
    controller: _search,
    decoration: InputDecoration(
      hintText: 'Search Complaints...',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    onChanged: (_) => setState(() {}),
  );
}

Widget _buildFilterButton() {
  return PopupMenuButton<String>(
    onSelected: (v) => setState(() => _filter = v),
    itemBuilder: (_) => [
      'All',
      'Pending',
      'Assigned',
      'In Progress',
      'Completed',
      'Resolved',
    ].map((f) => PopupMenuItem(value: f, child: Text(f))).toList(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 6),
          Text(_filter),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    ),
  );
}
}
