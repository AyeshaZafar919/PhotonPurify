import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceDashboard extends StatelessWidget {
  final String plantId;

  const MaintenanceDashboard({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final componentsRef = FirebaseFirestore.instance
        .collection("clients")
        .doc(plantId)
        .collection("components");

    final alertsRef = FirebaseFirestore.instance
        .collection("clients")
        .doc(plantId)
        .collection("alerts");

    final logsRef = FirebaseFirestore.instance
        .collection("clients")
        .doc(plantId)
        .collection("maintenance_logs");

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Maintenance Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ======================================================
            // SYSTEM OVERVIEW (TESLA CARD)
            // ======================================================
            StreamBuilder(
              stream: componentsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                int critical =
                    docs.where((c) => c['status'] == "Critical").length;
                int warnings =
                    docs.where((c) => c['status'] == "Warning").length;
                int total = docs.length;

                return _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SYSTEM HEALTH",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem("Total", total.toString(), Icons.devices),
                          _statItem("Critical", critical.toString(),
                              Icons.error, Colors.redAccent),
                          _statItem("Warnings", warnings.toString(),
                              Icons.warning, Colors.orangeAccent),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ======================================================
            // COMPONENT HEALTH
            // ======================================================
            const Text(
              "Component Health",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder(
              stream: componentsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    return _componentCard(doc);
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // ======================================================
            // ALERTS
            // ======================================================
            const Text(
              "Alerts",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder(
              stream: alertsRef.orderBy("timestamp", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: snapshot.data!.docs.map((alert) {
                    return _alertTile(alert);
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // ======================================================
            // MAINTENANCE HISTORY
            // ======================================================
            const Text(
              "Maintenance History",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder(
              stream: logsRef.orderBy("date", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: snapshot.data!.docs.map((log) {
                    final date = (log['date'] as Timestamp).toDate();

                    return _glassTile(
                      icon: Icons.history,
                      title: "${log.id} • ${log['action']}",
                      subtitle:
                          "${date.day}/${date.month}/${date.year} • ${log['technician']}",
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

  // ======================================================
  // TESLA GLASS CARD
  // ======================================================
  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }

  // ======================================================
  // STATS
  // ======================================================
  Widget _statItem(String title, String value, IconData icon,
      [Color color = Colors.white]) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(title, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  // ======================================================
  // COMPONENT CARD (TESLA STYLE)
  // ======================================================
  Widget _componentCard(DocumentSnapshot doc) {
    String name = doc.id;
    String status = doc['status'];

    double used = _calculateUsagePercent(doc.data() as Map<String, dynamic>);
    double remaining = 100 - used;

    Color statusColor = status == "Good"
        ? Colors.greenAccent
        : status == "Warning"
            ? Colors.orangeAccent
            : Colors.redAccent;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: used / 100,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),

          const SizedBox(height: 8),

          Text("Wear: ${used.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white70)),
          Text("Remaining: ${remaining.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ======================================================
  // ALERT TILE
  // ======================================================
  Widget _alertTile(DocumentSnapshot alert) {
    return _glassTile(
      icon: Icons.notification_important,
      title: alert['messege'],
      subtitle: alert['severity'].toUpperCase(),
      color: alert['severity'] == "urgent"
          ? Colors.redAccent
          : Colors.orangeAccent,
    );
  }

  Widget _glassTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ======================================================
  double _calculateUsagePercent(Map<String, dynamic> c) {
    if (c.containsKey("cumulative_days")) {
      return (c["cumulative_days"] / c["total_life_days"]) * 100;
    }
    if (c.containsKey("cummulative_cycles")) {
      return (c["cummulative_cycles"] / c["total_life_cycles"]) * 100;
    }
    if (c.containsKey("cummulative_revolutions")) {
      return (c["cummulative_revolutions"] /
              c["total_life_revolutions"]) *
          100;
    }
    if (c.containsKey("cummulative_usage")) {
      return (c["cummulative_usage"] / c["total_life_usage"]) * 100;
    }
    return 0;
  }
}