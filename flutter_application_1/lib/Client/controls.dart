import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ControlsPage extends StatefulWidget {
  final String plantId;

  const ControlsPage({super.key, required this.plantId});

  @override
  State<ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  final firestoreDoc =
      FirebaseFirestore.instance.collection('clients').doc('widget.plantId');

  final rtdbRef =
    rtdb.FirebaseDatabase.instance.ref('devices/client1/controls');

  String cleaningMode = "AUTOMATIC";
  bool isCleaning = false;
  String? scheduledTime;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _incrementCleaningCycles() async {
  final sensorsRef =
      rtdb.FirebaseDatabase.instance.ref('devices/${widget.plantId}/sensors-data');

  await sensorsRef.runTransaction((data) {
    final current = Map<String, dynamic>.from(data as Map? ?? {});

    int total = current['cleaning_cycles'] ?? 0;
    int today = current['today_cleaning_cycles'] ?? 0;

    current['cleaning_cycles'] = total + 1;
    current['today_cleaning_cycles'] = today + 1;

    return rtdb.Transaction.success(current);
  });
}

Future<void> _sendNotification(String title, String message) async {
  await FirebaseFirestore.instance.collection('notificationss').add({
    "title": title,
    "message": message,
    "timestamp": FieldValue.serverTimestamp(),
    "type": "system",
    "plantId": widget.plantId, // ✅ ADD THIS
  });
}

  Future<void> _loadData({bool showSnackbar = false}) async {
    setState(() => loading = true);

    try {
      final snap = await rtdbRef.get();
      final data = snap.value as Map<dynamic, dynamic>? ?? {};

      setState(() {
        cleaningMode = data['cleaningMode'] ?? "AUTOMATIC";
        isCleaning = data['manualCleaning'] == "ON";
        scheduledTime = data['scheduledTime'] ?? "Not set";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateMode(String mode) async {
    setState(() {
      cleaningMode = mode;
      if (mode != "MANUAL") isCleaning = false;
    });

    await rtdbRef.update({"cleaningMode": mode});
    await firestoreDoc.set({"cleaningMode": mode}, SetOptions(merge: true));
  }

  Future<void> _toggleManualCleaning() async {
  final newState = isCleaning ? "OFF" : "ON";

  setState(() => isCleaning = !isCleaning);

  await rtdbRef.update({"manualCleaning": newState});

  if (newState == "ON") {
    // ✅ Increment cycles
    await _incrementCleaningCycles();

    // ✅ Notification
    await _sendNotification(
      "Cleaning Started",
      "Manual cleaning has been started.",
    );
  } else {
    await _sendNotification(
      "Cleaning Stopped",
      "Manual cleaning has been stopped.",
    );
  }
}

  Future<void> _pickTime() async {
  final picked =
      await showTimePicker(context: context, initialTime: TimeOfDay.now());

  if (picked != null) {
    final time = picked.format(context);

    setState(() => scheduledTime = time);

    await rtdbRef.update({"scheduledTime": time});

    // ✅ Notification
    await _sendNotification(
      "Cleaning Scheduled",
      "Cleaning has been scheduled at $time.",
    );
  }
}

  // ---------------- TESLA BACKGROUND ----------------

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff05070F),
            Color(0xff0A0F1C),
            Color(0xff05070F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return FadeInDown(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CONTROL SYSTEM",
                  style: TextStyle(color: Colors.white70)),

              Text(
                "PHOTON PURIFY",
                style: GoogleFonts.poppins(
                  color: Colors.cyanAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.bolt, color: Colors.cyanAccent, size: 30),
        ],
      ),
    );
  }

  // ---------------- TESLA MODE CARD ----------------

  Widget _buildModeCard({
    required String mode,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final selected = cleaningMode == mode;

    return ZoomIn(
      child: GestureDetector(
        onTap: () => _updateMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.8),
                      Colors.black,
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xff141C2B),
                      Color(0xff0C111D),
                    ],
                  ),
            border: Border.all(
              color: selected ? Colors.cyanAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(width: 12),
                  Text(
                    mode,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle, color: Colors.cyanAccent),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                description,
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 14),

              // ---------------- MODE ACTIONS ----------------

              if (mode == "MANUAL" && selected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCleaning ? "ACTIVE" : "STANDBY",
                      style: TextStyle(
                        color: isCleaning ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _teslaButton(
                      label: isCleaning ? "STOP" : "START",
                      icon: isCleaning ? Icons.stop : Icons.play_arrow,
                      color: isCleaning ? Colors.red : Colors.green,
                      onTap: _toggleManualCleaning,
                    ),
                  ],
                ),

              if (mode == "SCHEDULED" && selected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      scheduledTime ?? "Not set",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    _teslaButton(
                      label: "SET TIME",
                      icon: Icons.alarm,
                      color: Colors.cyanAccent,
                      onTap: _pickTime,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- TESLA BUTTON ----------------

  Widget _teslaButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0F1C),
      appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        "CONTROLS",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      //actions: const [NotificationIcon()],
    ),
      body: Stack(
        children: [

          // BACKGROUND
          _background(),

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _header(),
                  const SizedBox(height: 30),

                  Text(
                    "Select Cleaning Mode",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildModeCard(
                    mode: "MANUAL",
                    description:
                        "Direct control over cleaning system operations.",
                    icon: Icons.power,
                    color: Colors.redAccent,
                  ),

                  const SizedBox(height: 16),

                  _buildModeCard(
                    mode: "SCHEDULED",
                    description:
                        "Automated cleaning at scheduled time daily.",
                    icon: Icons.schedule,
                    color: Colors.orangeAccent,
                  ),

                  const SizedBox(height: 16),

                  _buildModeCard(
                    mode: "AUTOMATIC",
                    description:
                        "AI-based smart cleaning optimization system.",
                    icon: Icons.auto_awesome,
                    color: Colors.greenAccent,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // LOADING OVERLAY
          if (loading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.cyanAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}