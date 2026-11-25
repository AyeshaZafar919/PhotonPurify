import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SystemPerformanceChart extends StatelessWidget {
  const SystemPerformanceChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('SolarPerformance')
          .orderBy('date', descending: false)
          .limitToLast(7) // Last 7 days
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Prepare data for charts
        List<FlSpot> energyData = [];
        List<FlSpot> efficiencyData = [];
        List<FlSpot> gainData = [];
        List<String> labels = [];

        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;

          double dailyEnergy = (data['dailyEnergy'] ?? 0).toDouble();
          double cleaningEfficiency = (data['cleaningEfficiency'] ?? 0)
              .toDouble();
          double performanceGain = (data['performanceGain'] ?? 0).toDouble();

          energyData.add(FlSpot(i.toDouble(), dailyEnergy));
          efficiencyData.add(FlSpot(i.toDouble(), cleaningEfficiency));
          gainData.add(FlSpot(i.toDouble(), performanceGain));

          // Correct way to handle Firestore Timestamp
          final timestamp = data['date'] as Timestamp;
          final dateTime = timestamp.toDate();

          // Format the date to MM/dd
          labels.add(DateFormat('MM/dd').format(dateTime));
        }

        return Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < labels.length) {
                                return Text(labels[value.toInt()]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: energyData,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData(
                          spots: efficiencyData,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData(
                          spots: gainData,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _Legend(color: Colors.blue, label: "Energy (kWh)"),
                    _Legend(color: Colors.green, label: "Cleaning Eff."),
                    _Legend(color: Colors.orange, label: "Perf. Gain"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({Key? key, required this.color, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
