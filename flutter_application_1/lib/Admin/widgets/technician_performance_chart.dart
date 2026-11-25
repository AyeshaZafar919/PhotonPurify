import 'package:ayesha_admin/Admin/pages/complaint_details_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianPerformanceChart extends StatefulWidget {
  @override
  _TechnicianPerformanceChartState createState() =>
      _TechnicianPerformanceChartState();
}

class _TechnicianPerformanceChartState extends State<TechnicianPerformanceChart> {
  List<String> technicians = [];
  List<int> resolvedCounts = [];
  List<int> pendingCounts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTechnicianPerformance();
  }

  Future<void> fetchTechnicianPerformance() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('complaints').get();

    Map<String, Map<String, int>> stats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final technician = data['technicianName'] ?? 'Unassigned';
      final status = data['status'] ?? 'In Progress';

      if (!stats.containsKey(technician)) {
        stats[technician] = {"resolved": 0, "In Progress": 0};
      }

      if (status == "Resolved") {
        stats[technician]!["resolved"] = stats[technician]!["resolved"]! + 1;
      } else {
        stats[technician]!["In Progress"] = stats[technician]!["In Progress"]! + 1;
      }
    }

    setState(() {
      technicians = stats.keys.toList();
      resolvedCounts = stats.values.map((e) => e["resolved"]!).toList();
      pendingCounts = stats.values.map((e) => e["In Progress"]!).toList();
      isLoading = false;
    });
  }

  void _navigateToTechnicianDetails(String technician) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianComplaintDetails(
          technicianName: technician,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          barGroups: List.generate(technicians.length, (index) {
            return BarChartGroupData(
              x: index,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  toY: resolvedCounts[index].toDouble(),
                  color: Colors.green,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: pendingCounts[index].toDouble(),
                  color: Colors.orange,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return GestureDetector(
                    onTap: () {
                      final technician = technicians[value.toInt()];
                      _navigateToTechnicianDetails(technician);
                    },
                    child: Text(
                      technicians[value.toInt()],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
