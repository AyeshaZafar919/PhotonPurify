import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class CleaningImpactChart extends StatefulWidget {
  const CleaningImpactChart({super.key});

  @override
  State<CleaningImpactChart> createState() => _CleaningImpactChartState();
}

class _CleaningImpactChartState extends State<CleaningImpactChart> {
  Map<String, double> deviceEfficiency = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllDevices();
  }

  Future<void> _fetchAllDevices() async {
    final ref = FirebaseDatabase.instance.ref("devices");

    final snapshot = await ref.get();

    if (snapshot.value == null) {
      setState(() => loading = false);
      return;
    }

    final Map data = snapshot.value as Map;

    Map<String, double> temp = {};

    data.forEach((deviceId, deviceData) {
      try {
        final sensors = deviceData["sensors-data"];

        double before =
            double.tryParse(sensors["Solar_Before"].toString()) ?? 0;
        double after =
            double.tryParse(sensors["Solar_After"].toString()) ?? 0;

        double gain = before > 0 ? ((after - before) / before) * 100 : 0;

        temp[deviceId] = gain;
      } catch (e) {
        // skip invalid device
      }
    });

    setState(() {
      deviceEfficiency = temp;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deviceEfficiency.isEmpty) {
      return const Center(child: Text("No device data found"));
    }

    final devices = deviceEfficiency.keys.toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff141C2B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: 12),

          Expanded(
  child: Stack(
    children: [

      // 🔥 CHART
      BarChart(
        BarChartData(
          maxY: 120,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${value.toInt()}%",
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                  );
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= devices.length) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "D${index + 1}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          barTouchData: BarTouchData(enabled: true),

          barGroups: List.generate(devices.length, (index) {
            final value = deviceEfficiency[devices[index]]!;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: value >= 10
                        ? [Colors.greenAccent, Colors.green]
                        : value >= 5
                            ? [Colors.orangeAccent, Colors.orange]
                            : [Colors.redAccent, Colors.red],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),

      // 🔥 VALUE LABELS (MODERN OVERLAY)
      Positioned.fill(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final chartHeight = constraints.maxHeight;
      final chartWidth = constraints.maxWidth;

      final barWidth = chartWidth / devices.length;

      return Stack(
        children: List.generate(devices.length, (index) {
          final value = deviceEfficiency[devices[index]]!;

          // 🔥 X POSITION (center of each bar)
          final x = barWidth * index + barWidth / 2;

          // 🔥 Y POSITION (EXACTLY top of bar)
          final y = chartHeight - (value / 120) * chartHeight;

          return Positioned(
            left: x - 30,
            top: y - 10, // 👈 small offset above bar
            child: Column(
              children: [
                // 🔥 VALUE LABEL
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${value.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 🔥 SMALL POINTER (optional but looks premium)
                Container(
                  width: 2,
                  height: 6,
                  color: Colors.white30,
                ),
              ],
            ),
          );
        }),
      );
    },
  ),
),
    ],
  ),
)
        ],
      ),
    );
  }
}