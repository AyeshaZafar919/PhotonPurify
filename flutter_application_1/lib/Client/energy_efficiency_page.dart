import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class EnergyEfficiencyPage extends StatelessWidget {
  final String plantId;

  const EnergyEfficiencyPage({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0F1C),

      appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        "EFFICENCY PANEL",
        style: GoogleFonts.poppins(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      //actions: const [NotificationIcon()],
    ),

      body: FutureBuilder<Map<String, double>>(
        future: _fetchSolarVoltages(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          final beforeV = snapshot.data!["before"]!;
          final afterV = snapshot.data!["after"]!;

          final double gain = beforeV > 0
              ? ((afterV - beforeV) / beforeV) * 100
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                FadeInDown(child: _header()),

                const SizedBox(height: 20),

                ZoomIn(child: _efficiencyCard(gain)),

                const SizedBox(height: 16),

                FadeInUp(child: _voltageCard(beforeV, afterV)),

                const SizedBox(height: 16),

                FadeInUp(child: _voltageBarChart(beforeV, afterV)),

                const SizedBox(height: 16),

                FadeInUp(child: _recommendationBox(gain)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Solar Performance",
                style: TextStyle(color: Colors.white70)),

            Text(
              "PHOTON PURIFY",
              style: GoogleFonts.poppins(
                color: Colors.cyanAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Icon(Icons.bolt, color: Colors.cyanAccent, size: 28),
      ],
    );
  }

  // ---------------- EFFICIENCY CARD ----------------

  Widget _efficiencyCard(double gain) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gain >= 10
              ? [Colors.greenAccent, Colors.black]
              : [Colors.orangeAccent, Colors.black],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "EFFICIENCY GAIN",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 10),

          Text(
            "${gain.toStringAsFixed(1)}%",
            style: GoogleFonts.poppins(
              fontSize: 34,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- VOLTAGE CARD ----------------

  Widget _voltageCard(double beforeV, double afterV) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff141C2B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _voltageBlock("Before", beforeV, Colors.redAccent),
          _voltageBlock("After", afterV, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _voltageBlock(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70)),

        const SizedBox(height: 6),

        Text(
          "${value.toStringAsFixed(2)} V",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------------- BAR CHART ----------------

  Widget _voltageBarChart(double beforeV, double afterV) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff0F1626),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: (beforeV > afterV ? beforeV : afterV) + 5,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),

            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: beforeV,
                    color: Colors.redAccent,
                    width: 30,
                  )
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: afterV,
                    color: Colors.cyanAccent,
                    width: 30,
                  )
                ],
              ),
            ],

            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt() == 0 ? "Before" : "After",
                      style: const TextStyle(color: Colors.white70),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- RECOMMENDATION ----------------

  Widget _recommendationBox(double gain) {
    String text = gain >= 15
        ? "Excellent performance. Tesla-grade efficiency achieved."
        : gain >= 5
            ? "Good improvement. Consider optimizing cleaning frequency."
            : "Low gain detected. Panel may require maintenance.";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff141C2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  // ---------------- FIREBASE ----------------

  Future<Map<String, double>> _fetchSolarVoltages() async {
    final ref =
        FirebaseDatabase.instance.ref("devices/$plantId/sensors-data");

    final snapshot = await ref.get();

    if (snapshot.value == null) {
      return {"before": 0, "after": 0};
    }

    final Map data = snapshot.value as Map;

    return {
      "before": double.tryParse(data["Solar_Before"].toString()) ?? 0,
      "after": double.tryParse(data["Solar_After"].toString()) ?? 0,
    };
  }
}