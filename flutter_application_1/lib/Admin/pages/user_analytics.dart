import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAnalyticsPage extends StatelessWidget {
  const UserAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFFF4F7FE),

  // 🔥 Modern App Bar (same style you wanted)
  appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,

  title: Text(
    'User Analytics',
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
        colors: [
          Color(0xFF020617), // deep black-blue
          Color(0xFF0F172A), // dark navy
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
),
  body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF020617), Color(0xFF0F172A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("users")
        .orderBy("createdAt", descending: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        );
      }

      final users = snapshot.data!.docs;

      int totalUsers = users.length;
      int activeUsers = users.where((u) => u["ustatus"] == "Active").length;
      int inactiveUsers = totalUsers - activeUsers;

      int adminCount = users.where((u) => u["urole"] == "Admin").length;
      int clientCount = users.where((u) => u["urole"] == "Client").length;
      int technicianCount = users.where((u) => u["urole"] == "Technician").length;

      final List<String> months = [
  "Jan","Feb","Mar","Apr","May","Jun",
  "Jul","Aug","Sep","Oct","Nov","Dec"
];

// Group by month
final Map<int, int> monthlyCounts = {};

for (var doc in users) {
  final data = doc.data() as Map<String, dynamic>;
  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
  if (createdAt == null) continue;

  monthlyCounts[createdAt.month] =
      (monthlyCounts[createdAt.month] ?? 0) + 1;
}

// cumulative
List<int> cumulative = [];
int running = 0;

for (int i = 1; i <= 12; i++) {
  running += (monthlyCounts[i] ?? 0);
  cumulative.add(running);
}

// find last valid month
int lastIndex = -1;
for (int i = 0; i < 12; i++) {
  if (monthlyCounts[i + 1] != null && monthlyCounts[i + 1]! > 0) {
    lastIndex = i;
  }
}

final displayMonths =
    lastIndex >= 0 ? months.sublist(0, lastIndex + 1) : months;

final displayValues =
    lastIndex >= 0 ? cumulative.sublist(0, lastIndex + 1) : cumulative;

final spots = [
  for (int i = 0; i < displayMonths.length; i++)
    FlSpot(i.toDouble(), displayValues[i].toDouble())
];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Overview",
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

    const SizedBox(height: 16),

            /// ================= KPI ROW =================
            Row(
              children: [
                Expanded(child: _darkKpi("Total", totalUsers, Colors.cyan)),
                const SizedBox(width: 10),
                Expanded(child: _darkKpi("Active", activeUsers, Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _darkKpi("Inactive", inactiveUsers, Colors.red)),
              ],
            ),

            const SizedBox(height: 16),

            Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "User Roles Distribution",
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

    const SizedBox(height: 16),

            /// ================= PIE CHART =================
            SizedBox(
  height: 220,
  child: PieChart(
    PieChartData(
      sectionsSpace: 3,
      centerSpaceRadius: 40,
      sections: [
        if (adminCount > 0)
          PieChartSectionData(
            value: adminCount.toDouble(),
            title: '$adminCount',
            color: Colors.blueAccent,
            radius: 60,
            titleStyle: const TextStyle(color: Colors.white),
          ),
        if (clientCount > 0)
          PieChartSectionData(
            value: clientCount.toDouble(),
            title: '$clientCount',
            color: Colors.orange,
            radius: 60,
            titleStyle: const TextStyle(color: Colors.white),
          ),
        if (technicianCount > 0)
          PieChartSectionData(
            value: technicianCount.toDouble(),
            title: '$technicianCount',
            color: Colors.purple,
            radius: 60,
            titleStyle: const TextStyle(color: Colors.white),
          ),
      ],
    ),
  ),
),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: const [
    _Legend(color: Colors.blueAccent, text: "Admin"),
    _Legend(color: Colors.orange, text: "Client"),
    _Legend(color: Colors.purple, text: "Tech"),
  ],
),

            const SizedBox(height: 16),

            Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "User Activity Status",
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

    const SizedBox(height: 16),

            /// ================= BAR CHART =================
            SizedBox(
  height: 250,
  child: BarChart(
    BarChartData(
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          );
        },
      ),

      borderData: FlBorderData(
        show: false,
      ),

      // 🔥 FIXED AXIS STYLES (WHITE TEXT)
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),

        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = "";

              switch (value.toInt()) {
                case 0:
                  text = "Active";
                  break;
                case 1:
                  text = "Inactive";
                  break;
              }

              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white, // ✅ FIXED
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),

        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white, // ✅ FIXED
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),

      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: activeUsers.toDouble(),
              color: Colors.greenAccent,
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: inactiveUsers.toDouble(),
              color: Colors.redAccent,
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ],
    ),
  ),
),
            const SizedBox(height: 16),

            Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "User growth over time",
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),


    const SizedBox(height: 16),

            /// ================= LINE CHART =================
            SizedBox(
  height: 250,
  child: LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          );
        },
      ),

      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.white12),
      ),

      // 🔥 FIXED AXIS LABEL COLORS (WHITE)
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),

        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();

              if (index >= 0 && index < displayMonths.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    displayMonths[index],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white, // ✅ FIXED
                    ),
                  ),
                );
              }
              return const Text("");
            },
          ),
        ),

        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white, // ✅ FIXED
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),

      lineBarsData: [
        if (spots.isNotEmpty)
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orangeAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),

            // 🔥 modern glow area
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.15),
            ),
          ),
      ],
    ),
  ),
),
          ],
        ),
      );
    },
  ),
),
);

  }

  Widget _darkKpi(String title, int value, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.4)),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 10,
        )
      ],
    ),
    child: Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Widget _darkCard({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _glassCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          spreadRadius: 2,
        )
      ],
    ),
    child: child,
  );
}

Widget _modernKpi(String title, int value, Color color) {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: value.toDouble()),
    duration: const Duration(milliseconds: 800),
    builder: (context, val, child) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              val.toInt().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    },
  );
}

Widget _legend(String label, Color color) {
  return Row(
    children: [
      Container(width: 10, height: 10, color: color),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}

  Widget _buildKpiCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

Widget _buildLegendItem(String label, Color color) {
  return Row(
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
