import 'package:ayesha_admin/Client/client_complaint_form.dart';
import 'package:flutter/material.dart';

class ClientDashboarddd extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Client Dashboard")),
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
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text("Welcome, Client!")),
    );
  }
}
