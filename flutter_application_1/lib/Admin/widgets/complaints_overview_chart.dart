import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintsChart extends StatefulWidget {
  const ComplaintsChart({Key? key}) : super(key: key);

  @override
  _ComplaintsChartState createState() => _ComplaintsChartState();
}

class _ComplaintsChartState extends State<ComplaintsChart> {
  String selectedFilter = "This Month";
  DateTimeRange? customRange;

  int pendingCount = 0;
  int assignedCount = 0;
  int resolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchComplaintsData();
  }

  Future<void> _fetchComplaintsData() async {
    DateTime startDate;
    DateTime endDate = DateTime.now();

    if (selectedFilter == "Today") {
      startDate = DateTime.now();
    } else if (selectedFilter == "This Week") {
      startDate = DateTime.now().subtract(const Duration(days: 7));
    } else if (selectedFilter == "This Month") {
      startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    } else if (selectedFilter == "Custom" && customRange != null) {
      startDate = customRange!.start;
      endDate = customRange!.end;
    } else {
      startDate = DateTime(2000); // Default → fetch all
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('complaints')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    int pending = 0;
    int assigned = 0;
    int resolved = 0;

    for (var doc in querySnapshot.docs) {
      final status = doc['status'] ?? '';
      if (status == 'Pending') pending++;
      if (status == 'In Progress') assigned++;
      if (status == 'Resolved') resolved++;
    }

    setState(() {
      pendingCount = pending;
      assignedCount = assigned;
      resolvedCount = resolved;
    });
  }

  void _onFilterChanged(String value) async {
    if (value == "Custom") {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2023),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          customRange = picked;
          selectedFilter = value;
        });
        _fetchComplaintsData();
      }
    } else {
      setState(() {
        selectedFilter = value;
      });
      _fetchComplaintsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Title + Filter Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Complaints Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ["Today", "This Week", "This Month", "Custom"].map((
                    filter,
                  ) {
                    return DropdownMenuItem(value: filter, child: Text(filter));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _onFilterChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 Stacked Bar Chart
            AspectRatio(
              aspectRatio: 1.6,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text("Pending");
                            case 1:
                              return const Text("Assigned");
                            case 2:
                              return const Text("Resolved");
                            default:
                              return const Text("");
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),

                  // 🔹 Add spacing between bars here
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: pendingCount.toDouble(),
                          color: Colors.orange,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: assignedCount.toDouble(),
                          color: Colors.blue,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: resolvedCount.toDouble(),
                          color: Colors.green,
                          width: 40,
                        ),
                      ],
                    ),
                  ],

                  // 🔹 New property for spacing
                  groupsSpace:
                      30, // <-- Adjust this value for more or less space
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🔹 Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend(Colors.orange, "Pending"),
                _buildLegend(Colors.blue, "Assigned"),
                _buildLegend(Colors.green, "Resolved"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
