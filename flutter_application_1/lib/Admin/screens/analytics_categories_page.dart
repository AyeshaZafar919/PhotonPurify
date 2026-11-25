import 'package:ayesha_admin/Admin/pages/complaints_analytics_page.dart';
import 'package:ayesha_admin/Admin/pages/technician_performace_analytics.dart';
import 'package:ayesha_admin/Admin/pages/user_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ayesha_admin/Admin/pages/cleaning_analytics_page.dart';
//import 'user_analytics.dart'; // 👈 import your UserAnalyticsPage

class AnalyticsCategoriesPage extends StatelessWidget {
  const AnalyticsCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        "title": "User Analytics",
        "icon": Icons.group,
        "color": Colors.blueAccent,
        "page": const UserAnalyticsPage(), // 👈 add navigation target
      },
      /*{
        "title": "Cleaning Cycle Analytics",
        "icon": Icons.cleaning_services,
        "color": Colors.green,
        "page": null, // placeholder, add later
      },
      {
        "title": "Alerts & Faults",
        "icon": Icons.warning_amber_rounded,
        "color": Colors.redAccent,
        "page": null,
      },*/
      {
        "title": "Technician Performance",
        "icon": Icons.build_circle,
        "color": Colors.purple,
        "page": const TechnicianAnalyticsPage(),
      },
      {
        "title": "Complaints Analytics",
        "icon": Icons.comment,
        "color": Colors.orange,
        "page": const ComplaintsAnalyticsPage(),
      },
      {
        "title": "Cleaning Cycles Analytics",
        "icon": Icons.cleaning_services,
        "color": Colors.greenAccent,
        "page": const CleaningAnalyticsPage(),
      },
      /*{
        "title": "System Performance",
        "icon": Icons.bolt,
        "color": Colors.teal,
        "page": null,
      },*/
    ];

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 800 ? 3 : (width > 480 ? 2 : 1);

    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      
      body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [

      _header(),

      const SizedBox(height: 12),

      Expanded(
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return _modernTile(
              context,
              category['title'],
              category['icon'],
              category['color'],
              category['page'],
              index,
            );
          },
        ),
      ),
    ],
  ),
),
    );
  }

  Widget _header() {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF020617), Color(0xFF0F172A)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.cyanAccent.withOpacity(0.15),
          blurRadius: 30,
        )
      ],
    ),
    child: const Row(
      children: [
        Icon(Icons.analytics, color: Colors.cyanAccent),
        SizedBox(width: 10),
        Text(
          "ANALYTICS HUB",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

Widget _modernTile(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
  Widget? page,
  int index,
) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 400 + (index * 120)),
    builder: (context, val, child) {
      return Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - val)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (page != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$title not implemented")),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                // 🔥 GLASS EFFECT
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
                ),

                border: Border.all(color: Colors.white12),

                // 🔥 GLOW
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 34),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
