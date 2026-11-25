import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class ComplaintsAnalyticsPage extends StatelessWidget {
  const ComplaintsAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ✅ MODERN DARK APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Complaints Analytics',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF020617), Color(0xFF0F172A)],
            ),
          ),
        ),
      ),

      // ✅ DARK BACKGROUND
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("complaints")
              .snapshots(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final complaints = snapshot.data!.docs;

            int total = complaints.length;
            int pending = complaints.where((c) => c["status"] == "Pending").length;
            int inProgress = complaints.where((c) => c["status"] == "In Progress").length;
            int resolved = complaints.where((c) => c["status"] == "Resolved").length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ===============================
                  // 🔷 SECTION TITLE
                  // ===============================
                  const Text(
                    "Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===============================
                  // 🔷 KPI GRID (3 IN ROW)
                  // ===============================
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                    children: [
                      _kpiCard("Total", total, Colors.cyanAccent),
                      _kpiCard("Resolved", resolved, Colors.greenAccent),
                      _kpiCard("Pending", pending, Colors.redAccent),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===============================
                  // 🔷 BAR CHART TITLE
                  // ===============================
                  const Text(
                    "Complaint Status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===============================
                  // 🔷 BAR CHART CARD
                  // ===============================
                  _statusBarChart(pending, inProgress, resolved),

                  const SizedBox(height: 20),

                  // ===============================
                  // 🔷 LINE CHART TITLE
                  // ===============================
                  const Text(
                    "Monthly Trends",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===============================
                  // 🔷 LINE CHART
                  // ===============================
                  _monthlyChart(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===============================
  // 🔷 MODERN KPI CARD
  // ===============================
  Widget _kpiCard(String title, int value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🔷 STATUS BAR CHART
  // ===============================
  Widget _statusBarChart(int pending, int inProgress, int resolved) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.white10),
            ),
            borderData: FlBorderData(show: false),

            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const labels = ["Pending", "Progress", "Resolved"];
                    if (value.toInt() < labels.length) {
                      return Text(
                        labels[value.toInt()],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),

              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),

              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),

            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(
                    toY: pending.toDouble(),
                    color: Colors.redAccent)
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(
                    toY: inProgress.toDouble(),
                    color: Colors.orange)
              ]),
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(
                    toY: resolved.toDouble(),
                    color: Colors.green)
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // 🔷 MONTHLY LINE CHART
  // ===============================
  Widget _monthlyChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("complaints")
          .orderBy("createdAt")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;

        final months = [
          "Jan","Feb","Mar","Apr","May","Jun",
          "Jul","Aug","Sep","Oct","Nov","Dec"
        ];

        Map<int, int> counts = {};
        for (var doc in docs) {
          final date = (doc["createdAt"] as Timestamp?)?.toDate();
          if (date == null) continue;
          counts[date.month] = (counts[date.month] ?? 0) + 1;
        }

        List<FlSpot> spots = [];
        for (int i = 1; i <= 12; i++) {
          spots.add(FlSpot((i - 1).toDouble(), (counts[i] ?? 0).toDouble()));
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),

                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.cyan.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}