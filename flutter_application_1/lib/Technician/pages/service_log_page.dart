import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceLogsPage extends StatelessWidget {
  const ServiceLogsPage({super.key});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "N/A";
    return DateFormat("dd MMM yyyy, hh:mm a").format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final String? technicianUid =
        FirebaseAuth.instance.currentUser?.uid;

    if (technicianUid == null) {
      return const Scaffold(
        body: Center(child: Text("No technician logged in.")),
      );
    }

    return Container(

      // 🔥 SAME GRADIENT AS TECHNICIAN DASHBOARD
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F2027), Color(0xFF1B2A33),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

      child: Scaffold(
        backgroundColor: Colors.transparent,

        // 🔥 MODERN APP BAR
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Service Logs",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("complaints")
              .where("technicianId", isEqualTo: technicianUid)
              .where("status", isEqualTo: "Completed")
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No completed tasks found.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            var logs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                var log = logs[index];

                String complaintId = log.id;
                String clientName = log['clientName'] ?? "Unknown Client";
                Timestamp? completedAt = log['completedAt'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [

                      // 🔥 ICON
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 🔥 CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Completed: ${_formatDate(completedAt)}",
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 🔥 NOTES
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("complaints")
                                  .doc(complaintId)
                                  .collection("notes")
                                  .orderBy("createdAt", descending: true)
                                  .snapshots(),
                              builder: (context, noteSnap) {
                                if (!noteSnap.hasData ||
                                    noteSnap.data!.docs.isEmpty) {
                                  return const Text(
                                    "No notes added",
                                    style: TextStyle(color: Colors.white38),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: noteSnap.data!.docs.map((n) {
                                    return Text(
                                      "• ${n['text']}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // 🔥 STATUS BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: const Text(
                          "Completed",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}