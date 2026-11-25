import 'package:ayesha_admin/Client/client_complaint_form.dart';
import 'package:ayesha_admin/Client/complaint.dart';
import 'package:ayesha_admin/Client/controls.dart';
import 'package:ayesha_admin/Client/dashboard/client_ui.dart';
import 'package:ayesha_admin/Client/energy_efficiency_page.dart';
import 'package:ayesha_admin/Client/insight.dart';
import 'package:ayesha_admin/Client/maintenance_dashboard.dart';
import 'package:ayesha_admin/Client/faq_page.dart'; // ✅ NEW IMPORT
import 'package:flutter/material.dart';

class ClientHomePage extends StatefulWidget {
  final String plantId;
  const ClientHomePage({Key? key, required this.plantId}) : super(key: key);

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _selectedIndex = 0;

  // ✅ Pages List (Added FAQ Page)
  List<Widget> get _pages => [
        ClientDashboard(plantId: widget.plantId),
        InsightPage(plantId: widget.plantId),
        ControlsPage(plantId: widget.plantId),
        ClientComplaintForm(plantId: widget.plantId),
        EnergyEfficiencyPage(plantId: widget.plantId),
        MaintenanceDashboard(plantId: widget.plantId),
        FAQPage(), // ✅ NEW PAGE
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: _pages[_selectedIndex],

      // 🔥 SCROLLABLE NAVBAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0F),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // ✅ KEY PART
          child: Row(
            children: [
              _navItem(Icons.dashboard, "Dash", 0),
              _navItem(Icons.bar_chart, "Insights", 1),
              _navItem(Icons.settings_remote, "Control", 2),
              _navItem(Icons.report_problem, "Complaint", 3),
              _navItem(Icons.energy_savings_leaf, "Energy", 4),
              _navItem(Icons.build, "Maintain", 5),
              _navItem(Icons.support_agent, "FAQ", 6), // ✅ NEW TAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? Colors.blueAccent : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blueAccent : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              width: isSelected ? 18 : 0,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}