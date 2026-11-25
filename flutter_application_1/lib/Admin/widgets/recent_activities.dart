import 'package:flutter/material.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      "User John updated profile",
      "Product added to inventory",
      "Backup completed successfully",
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 10),
            ...activities.map((activity) => ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: Text(activity),
                )),
          ],
        ),
      ),
    );
  }
}
