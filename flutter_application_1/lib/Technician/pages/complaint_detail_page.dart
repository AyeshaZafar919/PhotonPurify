import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;
  final Map<String, dynamic> complaintData;

  const ComplaintDetailPage({
    super.key,
    required this.complaintId,
    required this.complaintData,
  });

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final TextEditingController _noteController = TextEditingController();

  String _mapStatus(String status) {
    switch (status) {
      case 'Assigned':
        return 'Pending';
      case 'In Progress':
        return 'In-Progress';
      case 'Completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .update({
        'status': newStatus,
        if (newStatus == "Completed")
          "completedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $newStatus")),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(widget.complaintId)
        .collection('notes')
        .add({
      'text': _noteController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _noteController.clear();
  }

  Widget _progressTracker(String status) {
    final steps = ['Pending', 'In-Progress', 'Completed'];
    final mappedStatus = _mapStatus(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: steps.map((s) {
        final active = steps.indexOf(s) <= steps.indexOf(mappedStatus);

        return Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  active ? Colors.tealAccent : Colors.grey.shade800,
              child: Icon(
                Icons.check,
                size: 16,
                color: active ? Colors.black : Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : Colors.white54,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientName =
        widget.complaintData['clientName'] ?? 'Unknown Client';
    final urgency = widget.complaintData['urgency'] ?? 'Normal';
    final description =
        widget.complaintData['description'] ?? 'No description';
    final status = widget.complaintData['status'] ?? 'Assigned';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      // 🔥 MODERN APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Complaint Details",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        children: [

          // 🔥 TOP CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgency == "High"
                          ? Colors.red
                          : urgency == "Medium"
                              ? Colors.orange
                              : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      urgency,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Progress Tracker",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _progressTracker(status),

          const SizedBox(height: 25),

          const Text(
            "Technician Notes",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Write a note...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.tealAccent),
                onPressed: _addNote,
              ),
            ),
          ),

          const SizedBox(height: 15),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .doc(widget.complaintId)
                .collection('notes')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              return Column(
                children: snapshot.data!.docs.map((note) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      note['text'] ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 25),

          // 🔥 ACTION BUTTONS
          if (status == 'Assigned')
            ElevatedButton(
              onPressed: () => _updateStatus('In Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Start Job",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (status == 'In Progress')
            ElevatedButton(
              onPressed: () => _updateStatus('Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Finish Job",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}