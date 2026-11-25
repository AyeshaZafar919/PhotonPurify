import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientComplaintForm extends StatefulWidget {
   final String plantId;

  const ClientComplaintForm({super.key, required this.plantId});

  @override
  State<ClientComplaintForm> createState() => _ClientComplaintFormState();
}

class _ClientComplaintFormState extends State<ClientComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _urgency = "Medium";
  String _clientName = "";
  bool _isSubmitting = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchClientName();
  }

  Future<void> _fetchClientName() async {
    try {
      if (_currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(_currentUser!.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _clientName = doc["uname"] ?? "Unknown Client";
          });
        }
      }
    } catch (_) {
      setState(() => _clientName = "Unknown Client");
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in first")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ref =
          FirebaseFirestore.instance.collection("complaints").doc();

      await ref.set({
        "complaintId": ref.id,
        "clientId": _currentUser!.uid,
        "clientName": _clientName,
        "clientEmail": _currentUser!.email ?? "",
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "urgency": _urgency,
        "status": "Pending",
        "assignedTechnicianId": null,
        "assignedTechnicianName": null,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint submitted successfully")),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() => _urgency = "Medium");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ================= TESLA INPUT STYLE =================
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.cyanAccent),
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _fieldContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Submit Complaint",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ================= BODY =================
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _glassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "CLIENT SUPPORT",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _fieldContainer(
                    child: TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          "Complaint Title", Icons.title),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _fieldContainer(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          "Description", Icons.description),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _fieldContainer(
                    child: DropdownButtonFormField<String>(
                      value: _urgency,
                      dropdownColor: const Color(0xFF1B1F2A),
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _inputDecoration("Urgency", Icons.warning),
                      items: ["Low", "Medium", "High"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _urgency = v!),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "SEND TO SUPPORT",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}