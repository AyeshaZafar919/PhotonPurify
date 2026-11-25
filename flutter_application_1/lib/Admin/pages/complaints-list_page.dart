import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintsListPage extends StatelessWidget {
  final String? status;
  final bool showAddButton;

  const ComplaintsListPage({
    Key? key,
    this.status,
    this.showAddButton = false,
  }) : super(key: key);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "in progress":
        return Colors.blue;
      case "resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Query complaintsQuery =
        FirebaseFirestore.instance.collection('complaints');

    if (status != null && status!.isNotEmpty) {
      complaintsQuery = complaintsQuery.where('status', isEqualTo: status);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0F1A),
        title: Text(
          status != null ? "$status Complaints" : "Complaints Center",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: complaintsQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Complaints Found",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          var complaints = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var data =
                  complaints[index].data() as Map<String, dynamic>;

              String statusText = data['status'] ?? 'Pending';
              String priority = data['priority'] ?? 'Normal';

              DateTime? createdAt;
              if (data['createdAt'] != null) {
                createdAt = (data['createdAt'] as Timestamp).toDate();
              }

              return TweenAnimationBuilder(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0.95, end: 1),
                builder: (context, double scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff141C2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ================= TITLE =================
                      Text(
                        data['complaintDescription'] ??
                            'No Description',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ================= INFO ROW =================
                      Row(
                        children: [
                          _chip(
                            "Status: $statusText",
                            _statusColor(statusText),
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            "Priority: $priority",
                            _priorityColor(priority),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Client: ${data['clientName'] ?? 'N/A'}",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),

                      Text(
                        "Technician: ${data['assignedTechnicianName'] ?? 'Unassigned'}",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),

                      const SizedBox(height: 6),

                      if (createdAt != null)
                        Text(
                          DateFormat("dd MMM yyyy • hh:mm a")
                              .format(createdAt),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ================= FLOATING BUTTON =================
      floatingActionButton: showAddButton
          ? FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              onPressed: () {
                Navigator.pushNamed(context, '/add_complaint');
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  // ================= CHIP WIDGET =================
  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}