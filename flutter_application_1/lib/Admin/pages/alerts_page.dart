import 'package:flutter/material.dart';
import '../utils/sample_data.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = sampleAlerts; // full list

    return Scaffold(
      appBar: AppBar(title: const Text('All Alerts')),
      body: ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(alert['title']!),
              subtitle: Text(alert['status']!),
              leading: const Icon(Icons.warning, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
