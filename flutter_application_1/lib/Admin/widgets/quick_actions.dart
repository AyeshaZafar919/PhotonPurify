import 'package:ayesha_admin/Admin/screens/alerts_faults_panel.dart';
import 'package:ayesha_admin/Admin/pages/alerts_page.dart';
import 'package:ayesha_admin/Admin/screens/analytics_page.dart';
import 'package:ayesha_admin/Admin/pages/filtered_plant_list_page.dart';
import 'package:ayesha_admin/Admin/pages/plant_form.dart';
import 'package:flutter/material.dart';
//import '../pages/add_device_page.dart';
//import '../pages/clean_system_page.dart';

class QuickActions extends StatelessWidget {
  final List<Map<String, dynamic>> actions = [
    {
      "title": "Add Device",
      "icon": Icons.add,
      "color": Colors.blue,
      "page": const PlantForm(),
    },
    {
      "title": "Clean System",
      "icon": Icons.cleaning_services,
      "color": Colors.green,
      "page": const FilteredPlantListPage(
        status: "Clean",
        name: "Clean ",
      ),
    },
    {
      "title": "Check Alerts",
      "icon": Icons.warning,
      "color": Colors.orange,
      "page": AlertsAndFaultsPage(),
    },
    {
      "title": "Generate Report",
      "icon": Icons.insert_chart,
      "color": Colors.purple,
      "page": AnalyticsReportsPage(),
    },
  ];

  QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => action["page"]),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: action["color"].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(9),
                    child: Row(
                      children: [
                        Icon(action["icon"], color: action["color"], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action["title"],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: action["color"],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
