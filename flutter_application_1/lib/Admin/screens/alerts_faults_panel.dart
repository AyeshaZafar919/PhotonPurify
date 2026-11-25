import 'package:ayesha_admin/Admin/pages/activities_page.dart';
import 'package:ayesha_admin/Admin/screens/analytics_page.dart';
import 'package:ayesha_admin/Admin/screens/complaint_panel.dart';
import 'package:ayesha_admin/Admin/screens/user_management.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }

class AlertsAndFaultsPage extends StatefulWidget {
  @override
  _AdminFaultsPanelState createState() => _AdminFaultsPanelState();
}

class _AdminFaultsPanelState extends State<AlertsAndFaultsPage> {
  String? selectedPlant = "All";
  String? selectedPriority = "All";
  String? selectedStatus = "All";

  // Dropdown filter values
  final List<String> plants = ["All", "Plant A", "Plant B", "Plant C"];
  final List<String> priorities = ["All", "High", "Medium", "Low"];
  final List<String> statuses = ["All", "Pending", "In Progress", "Resolved"];

  /// 🔹 Assign a Technician to a Fault
  Future<void> _assignTechnician(String faultId) async {
    final technicianSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('urole', isEqualTo: 'Technician')
        .get();

    if (technicianSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No technicians available!')),
      );
      return;
    }

    String? selectedTechnicianId = technicianSnapshot.docs.first.id;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assign Technician"),
          content: DropdownButtonFormField<String>(
            value: selectedTechnicianId,
            items: technicianSnapshot.docs.map((doc) {
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc['uname']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTechnicianId = value!;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedTechnicianId != null) {
                  final technicianDoc = technicianSnapshot.docs.firstWhere(
                    (doc) => doc.id == selectedTechnicianId,
                  );

                  await FirebaseFirestore.instance
                      .collection('faults')
                      .doc(faultId)
                      .update({
                        'assignedTechnicianId': selectedTechnicianId,
                        'assignedTechnicianName': technicianDoc['uname'],
                        'status': 'In Progress',
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Technician Assigned Successfully")),
                  );
                }
              },
              child: const Text("Assign"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Update Fault Status (Pending → In Progress → Resolved)
  Future<void> _updateFaultStatus(String faultId, String currentStatus) async {
    String nextStatus;

    if (currentStatus == 'Pending') {
      nextStatus = 'In Progress';
    } else if (currentStatus == 'In Progress') {
      nextStatus = 'Resolved';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This fault is already resolved!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('faults').doc(faultId).update({
      'status': nextStatus,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Status updated to $nextStatus")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070F),

      body: Column(
        children: [

          _header(),
          const SizedBox(height: 12),

          /// FILTERS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _glassDropdown("Priority", selectedPriority, priorities,
                      (v) => setState(() => selectedPriority = v)),
                  _glassDropdown("Status", selectedStatus, statuses,
                      (v) => setState(() => selectedStatus = v)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// LIST
          Expanded(
  child: DefaultTabController(
    length: 2,
    child: Column(
      children: [

        /// 🔹 TABS
        const TabBar(
          indicatorColor: Colors.cyanAccent,
          tabs: [
            Tab(text: "Faults"),
            Tab(text: "Notifications"),
          ],
        ),

        /// 🔹 TAB CONTENT
        Expanded(
          child: TabBarView(
            children: [

              /// ================= FAULTS =================
              _buildFaultsList(),

              /// ================= NOTIFICATIONS =================
              _buildNotificationsList(),
            ],
          ),
        ),
      ],
    ),
  ),
),
        ],
      ),
    );
  }

  /// 🔹 Helper Function for Dropdowns
  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _header() {
  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF020617)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
        )
      ],
    ),
    child: const Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.cyanAccent),
        SizedBox(width: 10),
        Text(
          "Alerts & Faults Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    ),
  );
}

Widget _glassDropdown(
  String label,
  String? value,
  List<String> items,
  Function(String?) onChanged,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF0F172A),
        style: const TextStyle(color: Colors.white),
        iconEnabledColor: Colors.cyanAccent,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget _faultCard(Map<String, dynamic> fault, String id) {
  Color statusColor;

  switch (fault['status']) {
    case 'Resolved':
      statusColor = Colors.greenAccent;
      break;
    case 'In Progress':
      statusColor = Colors.orangeAccent;
      break;
    default:
      statusColor = Colors.redAccent;
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF0F172A),
      border: Border.all(color: Colors.white10),
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(0.15),
          blurRadius: 15,
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Top Row
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: statusColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fault['plantName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _statusChip(fault['status'], statusColor),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          fault['description'] ?? "",
          style: const TextStyle(color: Colors.white60),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            _infoBox("Priority", fault['priority']),
            const SizedBox(width: 8),
            _infoBox("Plant", fault['plantName']),
          ],
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
            color: const Color(0xFF1E293B),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'assign') {
                _assignTechnician(id);
              } else {
                _updateFaultStatus(id, fault['status']);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'assign', child: Text("Assign Technician")),
              const PopupMenuItem(value: 'resolve', child: Text("Mark Resolved")),
            ],
          ),
        )
      ],
    ),
  );
}

Widget _statusChip(String status, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontSize: 12),
    ),
  );
}

Widget _infoBox(String title, String value) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      "$title: $value",
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    ),
  );
}

Widget _buildFaultsList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('faults')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final matchesPriority = selectedPriority == "All" ||
            data['priority'] == selectedPriority;

        final matchesStatus = selectedStatus == "All" ||
            data['status'] == selectedStatus;

        return matchesPriority && matchesStatus;
      }).toList();

      if (docs.isEmpty) {
        return const Center(
          child: Text("No faults found",
              style: TextStyle(color: Colors.white70)),
        );
      }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          return _faultCard(data, docs[index].id);
        },
      );
    },
  );
}

Widget _buildNotificationsList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('notificationss')
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        );
      }

      final docs = snapshot.data!.docs;

      if (docs.isEmpty) {
        return const Center(
          child: Text("No notifications",
              style: TextStyle(color: Colors.white70)),
        );
      }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;

          return _notificationCard(data);
        },
      );
    },
  );
}

Widget _notificationCard(Map<String, dynamic> data) {
  final isFault = data["type"] == "fault";

  final time = data["timestamp"] != null
      ? (data["timestamp"] as Timestamp).toDate()
      : DateTime.now();

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF0F172A),
      border: Border.all(color: Colors.white10),
      boxShadow: [
        BoxShadow(
          color: isFault
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.cyanAccent.withOpacity(0.15),
          blurRadius: 12,
        )
      ],
    ),
    child: Row(
      children: [

        /// ICON
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFault
                ? Colors.redAccent.withOpacity(0.15)
                : Colors.cyanAccent.withOpacity(0.15),
          ),
          child: Icon(
            isFault ? Icons.error_outline : Icons.notifications,
            color: isFault ? Colors.redAccent : Colors.cyanAccent,
          ),
        ),

        const SizedBox(width: 12),

        /// TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data["message"] ?? "",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                data["plantId"] ?? "Unknown Plant",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _formatTime(time),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 1) return "Just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";

  return "${time.day}/${time.month}";
}
}
