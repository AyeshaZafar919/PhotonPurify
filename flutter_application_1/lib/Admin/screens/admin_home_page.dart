import 'package:ayesha_admin/Admin/pages/activities_page.dart';
import 'package:ayesha_admin/Admin/screens/admin_dashboard.dart';
import 'package:ayesha_admin/Admin/screens/alerts_faults_panel.dart';
import 'package:ayesha_admin/Admin/screens/analytics_categories_page.dart';
import 'package:ayesha_admin/Admin/screens/analytics_page.dart';
import 'package:ayesha_admin/Admin/screens/complaint_panel.dart';
import 'package:ayesha_admin/Admin/screens/user_management.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CeruleanThemePage extends StatefulWidget {
  const CeruleanThemePage({super.key});

  @override
  State<CeruleanThemePage> createState() => _CeruleanThemePageState();
}

class _CeruleanThemePageState extends State<CeruleanThemePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const UserManagementPage(),
    AnalyticsCategoriesPage(),
    ComplaintPanel(),
    AlertsAndFaultsPage(),
  ];

  // 🔹 Titles for each page’s AppBar
  final List<String> _titles = [
    "Dashboard",
    "User Management",
    "Analytics",
    "Complaints",
    "Alerts",
  ];

  // 🔹 Drawer Builder
  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }

  @override
Widget build(BuildContext context) {
  final User? user = FirebaseAuth.instance.currentUser;

  return Scaffold(
     backgroundColor: const Color(0xFF020617),
    extendBody: false, // important for modern nav effect

    // 🔥 MODERN FLOATING APP BAR
    appBar: AppBar(
  backgroundColor: const Color(0xFF0F172A), // FIX: removes white background issue
  elevation: 0,
  centerTitle: true,

  title: Text(
    _titles[_currentIndex],
    style: GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: 0.5,
    ),
  ),

  iconTheme: const IconThemeData(color: Colors.white),

  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_none, color: Colors.white),
      tooltip: "Notifications",
      onPressed: () {},
    ),

    IconButton(
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      tooltip: "Logout",
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      },
    ),
  ],
),
    // 🔥 MODERN BACKGROUND
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _pages[_currentIndex],
    ),

    // 🔥 MODERN GLASS BOTTOM NAVIGATION
    bottomNavigationBar: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          elevation: 0,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white60,
          showSelectedLabels: true,
          showUnselectedLabels: false,

          onTap: (index) => setState(() => _currentIndex = index),

          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Users",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: "Analytics",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: "Complaints",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber),
              label: "Alerts",
            ),
          ],
        ),
      ),
    ),
  );
}

  // Bottom Nav Icon builder
  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: isActive ? 2 : 0),
      child: Icon(
        icon,
        size: isActive ? 23 : 20,
        color: isActive ? Colors.white : Colors.white70,
      ),
    );
  }
}
