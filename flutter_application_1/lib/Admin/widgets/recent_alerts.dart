import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentAlerts extends StatelessWidget {
  const RecentAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 10),

            // === Fetch top 3 alerts ===
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .orderBy('createdAt', descending: true) // newest first
                  .limit(3) // only top 3
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text("Something went wrong");
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No recent alerts found");
                }

                final alerts = snapshot.data!.docs;

                return Column(
                  children: alerts.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? "No Title";
                    final description = data['description'] ?? "No Description";

                    return ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(title),
                      subtitle: Text(description),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
