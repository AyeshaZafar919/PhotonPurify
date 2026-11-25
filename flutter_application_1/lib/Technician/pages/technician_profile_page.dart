import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({super.key});

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  String name = "Technician";
  String skills = "General";
  String contact = "Not provided";
  bool isAvailable = true;
  int completedTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCompletedTasks();
  }

  Future<void> _loadProfile() async {
    if (uid == null) return;

    var doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (doc.exists) {
      setState(() {
        name = doc["uname"] ?? "Technician";
        skills = doc["specialization"] ?? "General";
        contact = doc["contact"] ?? "Not provided";
        isAvailable = doc["avalability"] ?? true;
      });
    }
  }

  Future<void> _loadCompletedTasks() async {
    if (uid == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection("complaints")
        .where("technicianId", isEqualTo: uid)
        .where("status", isEqualTo: "Completed")
        .get();

    setState(() {
      completedTasks = snapshot.docs.length;
    });
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => isAvailable = value);

    if (uid != null) {
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "avalability": isAvailable,
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // 🔥 FULL GRADIENT BACKGROUND
      body: Container(
        width: double.infinity,
    height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027), Color(0xFF1B2A33)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔥 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                // 🔥 PROFILE CARD
                _card(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Skills: $skills",
                                style: const TextStyle(
                                    color: Colors.white70)),
                            Text("Contact: $contact",
                                style: const TextStyle(
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 🔥 AVAILABILITY
                _card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Availability",
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: isAvailable,
                        onChanged: _toggleAvailability,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 🔥 COMPLETED TASKS
                _card(
                  child: Column(
                    children: [
                      const Text(
                        "Completed Tasks",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$completedTasks",
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 MODERN GLASS CARD
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}