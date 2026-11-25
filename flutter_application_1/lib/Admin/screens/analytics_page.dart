import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsReportsPage extends StatelessWidget {
  const AnalyticsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream =
        FirebaseFirestore.instance.collection("users").snapshots();
    final complaintsStream =
        FirebaseFirestore.instance.collection("complaints").snapshots();

    return Scaffold(
      
      body: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = userSnapshot.data!.docs;
          final totalUsers = users.length;
          final activeUsers =
              users.where((u) => u["ustatus"] == "Active").length;
          final technicians =
              users.where((u) => u["urole"] == "Technician").length;

          return StreamBuilder<QuerySnapshot>(
            stream: complaintsStream,
            builder: (context, complaintSnapshot) {
              if (!complaintSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final complaints = complaintSnapshot.data!.docs.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 KPI Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(
                            title: "Total Users",
                            value: "$totalUsers",
                            color: Colors.blue),
                        _StatCard(
                            title: "Active Users",
                            value: "$activeUsers",
                            color: Colors.green),
                        _StatCard(
                            title: "Complaints",
                            value: "$complaints",
                            color: Colors.orange),
                        _StatCard(
                            title: "Technicians",
                            value: "$technicians",
                            color: Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 🔹 User Status Distribution
                    const _SectionTitle("User Status Distribution"),
                    _ChartCard(
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: activeUsers.toDouble(),
                              title: "Active",
                              color: Colors.green,
                            ),
                            PieChartSectionData(
                              value: (totalUsers - activeUsers).toDouble(),
                              title: "Inactive",
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🔹 User Roles
                    const _SectionTitle("User Roles"),
                    _ChartCard(
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                                value: technicians.toDouble(),
                                title: "Technicians",
                                color: Colors.purple),
                            PieChartSectionData(
                                value: (totalUsers - technicians).toDouble(),
                                title: "Others",
                                color: Colors.teal),
                          ],
                        ),
                      ),
                    ),

                    // 🔹 Complaints Trend (live count for now)
                    const _SectionTitle("Complaints Trend"),
                    _ChartCard(
                      child: BarChart(
                        BarChartData(
                          barGroups: [
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: complaints.toDouble(),
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

// 🔹 KPI Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 110,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            const SizedBox(height: 6),
            Center(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Chart Container
class _ChartCard extends StatelessWidget {
  final Widget child;

  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 220, child: child),
      ),
    );
  }
}

// 🔹 Section Title
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
