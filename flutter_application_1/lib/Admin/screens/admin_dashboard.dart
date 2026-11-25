import 'package:ayesha_admin/Admin/pages/complaints-list_page.dart';
import 'package:ayesha_admin/Admin/pages/filtered_plant_list_page.dart';
import 'package:ayesha_admin/Admin/pages/cleaning_impact_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  double avgEfficiency = 0;
bool efficiencyLoading = true;
int totalPlants = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalPlants();

     WidgetsBinding.instance.addPostFrameCallback((_) {
    _calculateAverageEfficiency();
  });

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  void _loadTotalPlants() {
  FirebaseFirestore.instance
      .collection('SolarPlants')
      .snapshots()
      .listen((snapshot) {
    setState(() {
      totalPlants = snapshot.docs.length;
    });
  });
}

  Future<void> _calculateAverageEfficiency() async {
  final ref = FirebaseDatabase.instance.ref("devices");
  final snapshot = await ref.get();

  if (snapshot.value == null) {
    print("❌ No data found");
    setState(() {
      avgEfficiency = 0;
      efficiencyLoading = false;
    });
    return;
  }

  final Map data = snapshot.value as Map;

  double total = 0;
  int count = 0;

  data.forEach((deviceId, deviceData) {
    try {
      print("📦 Device: $deviceId");

      final sensors = deviceData["sensors-data"];

      if (sensors == null) {
        print("⚠️ sensors-data is null");
        return;
      }

      double before = (sensors["Solar_Before"] is num)
    ? (sensors["Solar_Before"] as num).toDouble()
    : double.tryParse(sensors["Solar_Before"].toString()) ?? 0;

double after = (sensors["Solar_After"] is num)
    ? (sensors["Solar_After"] as num).toDouble()
    : double.tryParse(sensors["Solar_After"].toString()) ?? 0;

      print("➡️ Before: $before | After: $after");

      if (before <= 0) {
        print("⚠️ Invalid before value");
        return;
      }

      double gain = ((after - before) / before) * 100;

      print("✅ Gain: $gain");

      total += gain;
      count++;
    } catch (e) {
      print("❌ Error: $e");
    }
  });

  //print("📊 Total: $total | Count: $count");

  setState(() {
  avgEfficiency = count > 0 ? total / count : 0;
  efficiencyLoading = false;

  //print("🔥 FINAL avgEfficiency: $avgEfficiency");
});
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF05070F),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= HERO =================
            _heroHeader(),

            const SizedBox(height: 12),

            // ================= KPI =================
            Row(
              children: [
                _animatedKpi("Plants", "$totalPlants", Icons.solar_power),
                _animatedKpi(
                  "Efficiency",
                  efficiencyLoading
                      ? "..."
                      : "${avgEfficiency.toStringAsFixed(1)}%",
                  Icons.bolt,
                ),
                _animatedKpi("Uptime", "99.3%", Icons.shield),
              ],
            ),

            const SizedBox(height: 12),

            // ================= GRID =================
            _controlGrid(context),

            const SizedBox(height: 12),

            // ================= AI PANEL =================
            _aiPanel(),

            const SizedBox(height: 12),

            // ================= CHART =================
            const Text(
              "Cleaning Impact Intelligence",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const CleaningImpactChart(),

            const SizedBox(height: 12),

            
          ],
        ),
      ),
    ),
  );
}
  // ================= HERO =================
 Widget _heroHeader() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xFF020617), Color(0xFF0F172A)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
        )
      ],
    ),
    child: Row(
      children: [

        const Icon(Icons.dashboard,
            color: Colors.cyanAccent, size: 30),

        const SizedBox(width: 12),

        // 🔥 FIXED RESPONSIVE SECTION
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "PHOTON PURIFY CONTROL CENTER",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18, // slightly reduced for safety
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Real-Time Solar Performance Center",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ================= ANIMATED KPI =================

Widget _animatedValue(String value) {
  double end = double.tryParse(value.replaceAll('%', '')) ?? 0;

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: end),
    duration: const Duration(seconds: 1),
    builder: (context, val, _) {
      return Text(
        "${val.toStringAsFixed(1)}${value.contains('%') ? '%' : ''}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    },
  );
}

  Widget _animatedKpi(String title, String value, IconData icon) {
  return Expanded(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Icon(icon, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 10),

                _animatedValue(value),

                Text(title,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  // ================= CONTROL GRID =================
 Widget _controlGrid(BuildContext context) {
  final data = [
    {
      "title": "Total Plants",
      "subtitle": "View all solar units",
      "icon": Icons.energy_savings_leaf,
      "color": Colors.blue,
      "page": const FilteredPlantListPage(name: "Total", showAddButton: true),
    },
    {
      "title": "Needs Cleaning",
      "subtitle": "Dust level high",
      "icon": Icons.cleaning_services,
      "color": Colors.orange,
      "page": const FilteredPlantListPage(
          status: "Needs Cleaning", name: "Needs Cleaning"),
    },
    {
      "title": "Recently Cleaned",
      "subtitle": "Plants Recently Cleaned",
      "icon": Icons.update,
      "color": Colors.green,
      "page": const FilteredPlantListPage(
          name: "Recently Cleaned", lastCleanedFilter: true),
    },
    {
      "title": "Complaints",
      "subtitle": "Pending issues",
      "icon": Icons.report_problem,
      "color": Colors.red,
      "page": const ComplaintsListPage(status: "Pending"),
    },
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: data.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
    ),
    itemBuilder: (context, index) {
      final item = data[index];

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (index * 150)),
        builder: (context, val, child) {
          return Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - val)),
              child: _modernTile(
                context,
                item["title"] as String,
                item["subtitle"] as String,
                item["icon"] as IconData,
                item["color"] as Color,
                item["page"] as Widget,
              ),
            ),
          );
        },
      );
    },
  );
}
  // ================= ANIMATED CARD =================
  Widget _modernTile(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
  Color color,
  Widget page,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        // 🔥 GLASS BACKGROUND
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        // 🔥 SOFT BORDER
        border: Border.all(color: Colors.white12),

        // 🔥 GLOW
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 25,
            spreadRadius: 1,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔥 TOP ROW
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // 🔥 BOTTOM STATUS BAR
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.2),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          
        ],
      ),
    ),
  );
}
  // ================= AI PANEL =================
  Widget _aiPanel() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('SolarPlants').snapshots(),
    builder: (context, plantSnapshot) {
      if (!plantSnapshot.hasData) {
        return const SizedBox();
      }

      final plants = plantSnapshot.data!.docs;

      DateTime now = DateTime.now();
      int recentlyCleaned = 0;
      int needsCleaning = 0;

      for (var doc in plants) {
        final data = doc.data() as Map<String, dynamic>;

        // 🔥 adjust field names if yours differ
        Timestamp? lastCleanedTs = data['lastCleaned'];

        if (lastCleanedTs != null) {
          DateTime lastCleaned = lastCleanedTs.toDate();

          if (now.difference(lastCleaned).inHours <= 6) {
            recentlyCleaned++;
          }
        }

        if (data['cleaningstatus'] == "Needs Cleaning") {
          needsCleaning++;
        }
        print("STATUS: ${data['cleaningstatus']}");
      }

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Complaints')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, complaintSnapshot) {
          int pendingComplaints =
              complaintSnapshot.data?.docs.length ?? 0;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyan.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ================= HEADER =================
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.cyanAccent),
                          SizedBox(width: 10),
                          Text(
                            "Overall System Report",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ================= STATS =================
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _miniStat(
                            "Recently Cleaned",
                            recentlyCleaned.toString(),
                            Colors.green,
                          ),
                          _miniStat(
                            "Needs Cleaning",
                            needsCleaning.toString(),
                            Colors.orange,
                          ),
                          _miniStat(
                            "Complaints",
                            pendingComplaints.toString(),
                            Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ================= ALERT SECTION =================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: Colors.orangeAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pendingComplaints > 0
                                    ? "$pendingComplaints pending complaints require attention"
                                    : "All systems operating normally",
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _miniStat(String title, String value, Color color) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 11,
        ),
      ),
    ],
  );
}
}