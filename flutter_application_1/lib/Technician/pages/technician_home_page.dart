import 'package:ayesha_admin/Technician/technician_dashboard.dart';
import 'package:ayesha_admin/Technician/pages/service_log_page.dart';
import 'package:ayesha_admin/Technician/pages/technician_profile_page.dart';
import 'package:flutter/material.dart';

class TechnicianHome extends StatefulWidget {
  const TechnicianHome({super.key});

  @override
  State<TechnicianHome> createState() => _TechnicianHomeState();
}

class _TechnicianHomeState extends State<TechnicianHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TechnicianDashboard(), // your dashboard page
    const ServiceLogsPage(),     // your logs page
    const TechnicianProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF121212),

    body: _pages[_selectedIndex],

    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        backgroundColor: Colors.transparent,
        elevation: 0,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white54,

        selectedFontSize: 12,
        unselectedFontSize: 11,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, size: 28),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, size: 28),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}
}
