import 'package:ayesha_admin/Admin/pages/activities_page.dart';
import 'package:ayesha_admin/Admin/screens/admin_dashboard.dart';
import 'package:ayesha_admin/Admin/pages/alerts_page.dart';
import 'package:ayesha_admin/Admin/screens/analytics_page.dart';
//import 'package:ayesha_admin/screens/complaints_page.dart';
import 'package:ayesha_admin/Admin/screens/user_management.dart';
import 'package:ayesha_admin/Admin/widgets/bottom_nav_bar.dart';
import 'package:ayesha_admin/Admin/widgets/system_performance_chart.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedindex=0;
  void navigatebottombar(int index)
  {
    setState(() {
      _selectedindex=index;
    });
  }

  final List<Widget> pages=[
    const AdminDashboard(),
     UserManagementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MyBottomNavBar(
        onTabChange:(index) => navigatebottombar(index) ,
      ),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Solar Panel Admin',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>  AnalyticsReportsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Alerts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Activities'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivitiesPage()),
                );
              },
            ),
            /*ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Complaints'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComplaintsPage()),
                );
              },
            ),*/
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SystemPerformanceChart(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedindex],
    );
  }
}