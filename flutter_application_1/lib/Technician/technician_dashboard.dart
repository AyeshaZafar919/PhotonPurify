import 'package:ayesha_admin/Technician/pages/complaint_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? technicianUid;
  String technicianName = "Technician";
  String speciality = "General";
  bool isAvailable = true; // Toggle availability

  // Search & Filter
  final TextEditingController _search = TextEditingController();
  String _filter = "All";

  @override
  void initState() {
    super.initState();
    technicianUid = _auth.currentUser?.uid;
    if (technicianUid != null) {
      _fetchTechnicianData();
    }
  }

  /// Fetch technician details from Firestore
  Future<void> _fetchTechnicianData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(technicianUid)
          .get();

      if (doc.exists) {
        setState(() {
          technicianName = doc['uname'] ?? "Technician";
          speciality = doc['specialization'] ?? "General";
          isAvailable = doc['avalability'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch technician data: $e");
    }
  }

  /// Toggle availability and update Firestore
  void _toggleAvailability() async {
    setState(() {
      isAvailable = !isAvailable;
    });

    if (technicianUid != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(technicianUid)
          .update({"avalability": isAvailable});
    }
  }

  Color _availabilityColor() {
    return isAvailable ? Colors.green : Colors.red;
  }

  @override
Widget build(BuildContext context) {
  if (technicianUid == null) {
    return const Scaffold(
      body: Center(child: Text("No technician logged in.")),
    );
  }

  return Scaffold(
    //extendBodyBehindAppBar: true,

    /// 🔥 MODERN APP BAR
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            technicianName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Text(
            speciality,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _toggleAvailability,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _availabilityColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _availabilityColor()),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: _availabilityColor()),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? "Available" : "Offline",
                    style: TextStyle(
                      color: _availabilityColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ),

    /// 🌙 DARK BACKGROUND
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF1B2A33)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          /// 🔍 SEARCH + FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _search,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search complaints...",
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                /// FILTER BUTTON
                PopupMenuButton<String>(
                  color: Colors.grey[900],
                  onSelected: (v) => setState(() => _filter = v),
                  itemBuilder: (_) => [
                    'All',
                    'Assigned',
                    'In Progress',
                    'Completed',
                  ]
                      .map((f) => PopupMenuItem(
                            value: f,
                            child: Text(
                              f,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list,
                            color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          _filter,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          /// 📋 COMPLAINT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('technicianId', isEqualTo: technicianUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No assigned complaints",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                var complaints = snapshot.data!.docs.where((doc) {
                  String title =
                      doc['title']?.toLowerCase() ?? "";
                  String description =
                      doc['description']?.toLowerCase() ?? "";
                  String clientName =
                      doc['clientName']?.toLowerCase() ?? "";
                  String id = doc.id.toLowerCase();
                  String status = doc['status'] ?? "";

                  bool matchesSearch = _search.text.isEmpty ||
                      title.contains(_search.text.toLowerCase()) ||
                      description
                          .contains(_search.text.toLowerCase()) ||
                      clientName
                          .contains(_search.text.toLowerCase()) ||
                      id.contains(_search.text.toLowerCase());

                  bool matchesFilter =
                      _filter == "All" ? true : status == _filter;

                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    var complaint = complaints[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            "👤 ${complaint['clientName']}",
                            style: const TextStyle(
                                color: Colors.white70),
                          ),
                          Text(
                            "⚡ ${complaint['urgency']}",
                            style: const TextStyle(
                                color: Colors.orangeAccent),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            complaint['description'],
                            style: const TextStyle(
                                color: Colors.white60),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                          complaint['status'])
                                      .withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  complaint['status'],
                                  style: TextStyle(
                                    color: _statusColor(
                                        complaint['status']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ComplaintDetailPage(
                                        complaintId:
                                            complaint.id,
                                        complaintData:
                                            complaint.data()
                                                as Map<String,
                                                    dynamic>,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("View"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Color code for status
  Color _statusColor(String status) {
    switch (status) {
      case "Assigned":
      case "Pending":
        return const Color.fromARGB(255, 219, 167, 89);
      case "In Progress":
        return const Color.fromARGB(255, 88, 152, 204);
      case "Resolved":
      case "Completed":
        return const Color.fromARGB(255, 81, 197, 85);
      default:
        return Colors.grey.shade300;
    }
  }
}
