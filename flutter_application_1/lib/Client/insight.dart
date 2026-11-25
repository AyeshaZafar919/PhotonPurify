import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

enum InsightFilter { weeklyCycles }

class InsightPage extends StatefulWidget {
  final String plantId;
  const InsightPage({super.key, required this.plantId});

  @override
  State<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _weeklyCyclesKey = GlobalKey();
  final DatabaseReference _realtimeDb = FirebaseDatabase.instance.ref();

  double totalCycles = 0.0;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    listenCleaningCycles();
  }

  void listenCleaningCycles() {
    _realtimeDb
        .child("devices/${widget.plantId}/sensors-data/cleaning_cycles")
        .onValue
        .listen((event) {
      final value = event.snapshot.value;

      double cycles = 0.0;

      if (value is num) {
        cycles = value.toDouble();
      } else if (value is String) {
        cycles = double.tryParse(value) ?? 0.0;
      }

      if (cycles != totalCycles) {
        setState(() {
          totalCycles = cycles;
          _pulse = true;
        });

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() => _pulse = false);
          }
        });
      }
    });
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0F1C),
      appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        "ANALYTICS",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      //actions: const [NotificationIcon()],
    ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("clients")
            .doc(widget.plantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final cleaningValues = List<num>.from(
            data['cleaningCyclesChart'] ?? [],
          ).map((e) => e.toDouble()).toList();

          final weeklyEnergy = (data['week_w'] ?? 0).toDouble();

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // HEADER
                FadeInDown(child: _header()),

                const SizedBox(height: 20),

                // ENERGY CARD
                ZoomIn(child: _mainCard(weeklyEnergy)),

                const SizedBox(height: 20),

                // LIVE CYCLES CARD
                FadeInUp(child: _liveCyclesCard()),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Weekly Cleaning Cycles",
                    key: _weeklyCyclesKey,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _buildBarChart(
                    cleaningValues,
                    Colors.cyanAccent,
                    labels: const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Energy Analytics",
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
        const Icon(Icons.bolt, color: Colors.cyanAccent),
      ],
    );
  }

  Widget _mainCard(double weeklyEnergy) {
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
          const Text("WEEKLY ENERGY",
              style: TextStyle(color: Colors.white70)),

          const SizedBox(height: 10),

          AnimatedFlipCounter(
            value: weeklyEnergy,
            suffix: " V",
            textStyle: GoogleFonts.poppins(
              fontSize: 30,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveCyclesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff141C2B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CLEANING CYCLES",
                  style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 6),

              AnimatedFlipCounter(
                value: totalCycles,
                duration: const Duration(milliseconds: 400),
                textStyle: GoogleFonts.poppins(
                  fontSize: 26,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          AnimatedScale(
            scale: _pulse ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.bolt, color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }

  // ---------------- CHART ----------------

  static Widget _buildBarChart(
    List<double> values,
    Color color, {
    required List<String> labels,
  }) {
    final maxY = values.isEmpty
        ? 10.0
        : (values.reduce((a, b) => a > b ? a : b) * 1.2);

    final barGroups = List.generate(values.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: values[i], color: color)
        ],
      );
    });

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int i = value.toInt();
                if (i >= 0 && i < labels.length) {
                  return Text(labels[i],
                      style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }
}