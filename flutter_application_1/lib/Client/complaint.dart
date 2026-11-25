import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({super.key});

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submitComplaint() {
    if (_formKey.currentState!.validate()) {
      // Here you can add API call to save complaint
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaint submitted successfully! Admins notified."),
        ),
      );
      // Clear the form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _image = null;
      });
    }
  }

  // 👉 NEW: Open extended complaint form as bottom sheet
  void _openExtendedForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows full height form
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: ExtendedComplaintForm(
          onSubmit: (title, description, image) {
            // You can handle submission here or call _submitComplaint logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Extended complaint submitted successfully!"),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  elevation: 0,
  centerTitle: true,

  // 🔹 Gradient Background (same as other screens)
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF005Fa7), Color(0xFF0089A7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),

  title: const Text(
    "Register Complaint",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      tooltip: "Add Extended Complaint",
      onPressed: _openExtendedForm,
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a title";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _image == null
                  ? ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Attach Image"),
                    )
                  : Column(
                      children: [
                        Image.file(_image!, height: 150),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text("Change Image"),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitComplaint,
                child: const Text("Submit Complaint"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Extended Complaint Form Widget
class ExtendedComplaintForm extends StatefulWidget {
  final Function(String, String, File?) onSubmit;
  const ExtendedComplaintForm({super.key, required this.onSubmit});

  @override
  State<ExtendedComplaintForm> createState() => _ExtendedComplaintFormState();
}

class _ExtendedComplaintFormState extends State<ExtendedComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _titleController.text,
        _descriptionController.text,
        _image,
      );
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _image = null);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Extended Complaint Form",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? "Please enter a title" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? "Please enter a description" : null,
            ),
            const SizedBox(height: 16),
            _image == null
                ? ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Attach Image"),
                  )
                : Column(
                    children: [
                      Image.file(_image!, height: 150),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text("Change Image"),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: const Text("Submit Complaint"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
