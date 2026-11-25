import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class CleaningAnalyticsPage extends StatefulWidget {
  const CleaningAnalyticsPage({super.key});

  @override
  State<CleaningAnalyticsPage> createState() =>
      _CleaningAnalyticsPageState();
}

class _CleaningAnalyticsPageState extends State<CleaningAnalyticsPage> {
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref("devices");

  Map<String, double> clientCycles = {};
  double totalCycles = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() {
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return;

      Map<String, double> temp = {};
      double total = 0;

      data.forEach((clientId, value) {
        final sensors =
            value["sensors-data"] as Map<dynamic, dynamic>?;

        double cycles = 0;

        if (sensors != null &&
            sensors["cleaning_cycles"] != null) {
          cycles = double.tryParse(
                  sensors["cleaning_cycles"].toString()) ??
              0;
        }

        temp[clientId.toString()] = cycles;
        total += cycles;
      });

      setState(() {
        clientCycles = temp;
        totalCycles = total;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0F1C),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 back button color
        ),

        title: Text(
          "Cleaning Analytics",
          style: GoogleFonts.poppins(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔥 TOTAL CARD
            _totalCard(),

            const SizedBox(height: 20),

            /// 📊 CHART
            Expanded(
              child: _chart(),
            ),

            const SizedBox(height: 20),

            /// 📋 CLIENT LIST
            Expanded(
              child: _clientList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TOTAL CARD ----------------

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff00C6FF), Color(0xff0072FF)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL CLEANING CYCLES",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            totalCycles.toInt().toString(),
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

  // ---------------- CHART ----------------

  Widget _chart() {
    List<BarChartGroupData> bars = [];
    int index = 0;

    clientCycles.forEach((client, value) {
      bars.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: Colors.cyanAccent,
              width: 16,
              borderRadius: BorderRadius.circular(6),
            )
          ],
        ),
      );
      index++;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff141C2B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          barGroups: bars,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < clientCycles.length) {
                    return Text(
                      clientCycles.keys
                          .toList()[value.toInt()],
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- CLIENT LIST ----------------

  Widget _clientList() {
    return ListView.builder(
      itemCount: clientCycles.length,
      itemBuilder: (context, index) {
        String client = clientCycles.keys.elementAt(index);
        double cycles = clientCycles[client]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff141C2B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                client,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
              ),
              Text(
                cycles.toInt().toString(),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}