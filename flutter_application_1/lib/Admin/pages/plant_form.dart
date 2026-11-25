import 'package:ayesha_admin/Admin/pages/filtered_plant_list_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class PlantForm extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const PlantForm({Key? key, this.docId, this.existingData}) : super(key: key);

  @override
  State<PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends State<PlantForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  DateTime? _installationDate;

  String? _selectedPlantStatus;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.existingData?['plantname'] ?? '');
    _locationController =
        TextEditingController(text: widget.existingData?['location'] ?? '');
    _capacityController = TextEditingController(
        text: widget.existingData?['capacity']?.toString() ?? '');
    _selectedPlantStatus = widget.existingData?['plantstatus'] ?? 'Active';

    if (widget.existingData?['installationdate'] != null &&
        widget.existingData!['installationdate'] is Timestamp) {
      _installationDate =
          (widget.existingData!['installationdate'] as Timestamp).toDate();
    }
  }

  void _savePlant() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final firestore = FirebaseFirestore.instance;
      final realtimeDB = FirebaseDatabase.instance.ref();

      String plantName = _nameController.text.trim();
      String deviceId = plantName; // 🔗 Device ID same as plant name

      final data = {
        "plantname": plantName,
        "location": _locationController.text,
        "capacity": double.tryParse(_capacityController.text) ?? 0,
        "plantstatus": _selectedPlantStatus ?? 'Active',
        "installationdate": _installationDate != null
            ? Timestamp.fromDate(_installationDate!)
            : FieldValue.serverTimestamp(),
        "cleaningstatus": "Clean", // default
        "lastcleaned": Timestamp.fromDate(now), // current time
        "deviceId": deviceId, // link to Realtime Database
      };

      try {
        if (widget.docId == null) {
          // New Plant
          await firestore.collection('SolarPlants').add(data);

          // --- Create Device Node in Realtime DB ---
          await realtimeDB.child("devices/$deviceId").set({
            "status": {
              "motor": "OFF",
              "pump": "OFF",
              "cleaningMode": "Automatic",
              "lastUpdated": now.toIso8601String(),
            },
            "sensors": {
              "dustLevel": 0,
              "temperature": 0,
              "voltage": 0,
              "current": 0,
            },
            "controls": {
              "startCleaning": false,
              "stopCleaning": false,
              "manualPump": false,
            }
          });
          // --- Create Client Document in Firestore ---
          await firestore.collection('clients').doc(plantName).set({
            "alertBatteryLow": false,
            "autoMode": false,
            "battery_level": 0,
            "battery_status": "nostatus",
            "chart": {
              "mon": 0,
              "tue": 0,
              "wed": 0,
              "thu": 0,
              "fri": 0,
              "sat": 0,
              "sun": 0,
            },
            "cleaningCyclesChart": [0, 0, 0, 0, 0, 0, 0],
            "cleaningMode": "Quick",
            "cleaning_status": "Active",
            "current_power_w": 0,
            "ecoMode": true,
            "energyAfterCleaning": [0, 0, 0, 0, 0, 0, 0],
            "energyBeforeCleaning": [0, 0, 0, 0, 0, 0, 0],
            "isCleaning": false,
            "month_kWh": 0,
            "monthlyChart": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            "notifyOnComplete": true,
            "output_power_kw": 0,
            "scheduledEnabled": false,
            "scheduledTime": Timestamp.fromDate(now),
            "showCleaningCycles": false,
            "showEnviromental": false,
            "temperatureUnit": "F",
            "theme": "Light",
            "timeFormat": "12h",
            "today_kWh": 0,
            "water_level": 0,
            "weather_impact": "No Disruption",
            "week_kWh": 0,
          });
        } else {
          // Update existing Plant (Firestore only)
          await firestore.collection('SolarPlants').doc(widget.docId).update(data);
        }


        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FilteredPlantListPage(
              name: "Total",
              showAddButton: true,
            ),
          ),
        );
      } catch (e) {
        print("❌ Error saving plant: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _pickInstallationDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _installationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _installationDate = picked;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      title: Text(widget.docId == null ? "Add Plant" : "Update Plant",style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),),
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff0F2027), Color(0xff203A43), Color(0xff2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= HEADER =================
                  const Text(
                    "Plant Configuration",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Create or update solar plant details",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= INPUT SECTION =================
                  _field(_nameController, "Plant Name", Icons.solar_power),
                  const SizedBox(height: 12),

                  _field(_locationController, "Location", Icons.location_on),
                  const SizedBox(height: 12),

                  _field(_capacityController, "Capacity (kW)", Icons.bolt,
                      isNumber: true),

                  const SizedBox(height: 15),

                  // ================= DATE =================
                  _glassTile(
                    icon: Icons.calendar_month,
                    title: _installationDate == null
                        ? "Select Installation Date"
                        : "Installed: ${_installationDate!.toLocal().toString().split(' ')[0]}",
                    onTap: _pickInstallationDate,
                  ),

                  const SizedBox(height: 15),

                  // ================= STATUS =================
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: _glassBox(),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPlantStatus,
                      dropdownColor: const Color(0xff1c1c1c),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Inactive', child: Text('Inactive')),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Plant Status",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedPlantStatus = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ================= SAVE BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePlant,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "SAVE PLANT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _field(TextEditingController controller, String label, IconData icon,
    {bool isNumber = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: _glassBox(),
    child: TextFormField(
      controller: controller,
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        icon: Icon(icon, color: Colors.cyanAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    ),
  );
}

Widget _glassTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

BoxDecoration _glassBox() {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.white24),
  );
}
}
