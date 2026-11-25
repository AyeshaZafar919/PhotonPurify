import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ActiveInactiveChart extends StatefulWidget {
  @override
  _ActiveInactiveChartState createState() => _ActiveInactiveChartState();
}

class _ActiveInactiveChartState extends State<ActiveInactiveChart> {
  int activeCount = 0;
  int inactiveCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlantStatus();
  }

  Future<void> _fetchPlantStatus() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('SolarPlants').get();

      int active = 0;
      int inactive = 0;

      for (var doc in snapshot.docs) {
        if (doc['plantstatus'] == "Active") {
          active++;
        } else if (doc['plantstatus'] == "Inactive") {
          inactive++;
        }
      }

      setState(() {
        activeCount = active;
        inactiveCount = inactive;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching plants: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = activeCount + inactiveCount;
    final activePercentage = total == 0 ? 0 : (activeCount / total) * 100;
    final inactivePercentage = total == 0 ? 0 : (inactiveCount / total) * 100;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Active vs. Inactive Plants",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 60,
                  sectionsSpace: 5,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: activeCount.toDouble(),
                      title: "${activePercentage.toStringAsFixed(1)}%",
                      radius: 70,
                      titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: inactiveCount.toDouble(),
                      title: "${inactivePercentage.toStringAsFixed(1)}%",
                      radius: 70,
                      titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend("Active Plants", Colors.green, activeCount),
                _buildLegend("Inactive Plants", Colors.red, inactiveCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 5),
        Text("$label: $count"),
      ],
    );
  }
}
