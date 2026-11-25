import 'package:ayesha_admin/Admin/pages/plant_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilteredPlantListPage extends StatelessWidget {
  final String? status;
  final bool lastCleanedFilter;
  final bool showAddButton;
  final String? name;

  const FilteredPlantListPage({
    Key? key,
    this.status,
    this.name,
    this.lastCleanedFilter = false,
    this.showAddButton = false,
  }) : super(key: key);

  void _deletePlant(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141C2B),
        title: const Text(
          "Delete Plant",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this plant?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('SolarPlants')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plant deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime fiveHoursAgo = now.subtract(const Duration(hours: 5));

    Query query =
        FirebaseFirestore.instance.collection('SolarPlants');

    if (lastCleanedFilter) {
      query = query
          .where('lastcleaned',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fiveHoursAgo))
          .where('lastcleaned',
              isLessThanOrEqualTo: Timestamp.fromDate(now));
    } else if (status != null) {
      query = query.where('cleaningstatus', isEqualTo: status);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          "$name Plants",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF005FA7), Color(0xFF0089A7)],
            ),
          ),
        ),
      ),

      // ================= BODY =================
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var plants = snapshot.data!.docs;

          if (plants.isEmpty) {
            return const Center(
              child: Text(
                "No plants found.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              var data =
                  plants[index].data() as Map<String, dynamic>;
              String docId = plants[index].id;

              String status = data['cleaningstatus'] ?? 'N/A';

              Color statusColor = status == "Clean"
                  ? Colors.green
                  : status == "Needs Cleaning"
                      ? Colors.red
                      : Colors.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),

                decoration: BoxDecoration(
                  color: const Color(0xff141C2B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                    )
                  ],
                ),

                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.orange.withOpacity(0.2),
                    child: const Icon(
                      Icons.solar_power,
                      color: Colors.orange,
                    ),
                  ),

                  title: Text(
                    data['plantname'] ?? "Unknown Plant",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _infoRow("Status", status, statusColor),
                        _infoRow("Efficiency",
                            "${data['efficiency'] ?? 'N/A'}%"),
                        _infoRow(
                          "Last Cleaned",
                          data['lastcleaned'] != null
                              ? DateFormat(
                                      'dd-MM-yyyy hh:mm a')
                                  .format((data['lastcleaned']
                                          as Timestamp)
                                      .toDate())
                              : "Not Available",
                        ),
                        _infoRow("Location",
                            data['location'] ?? 'N/A'),
                      ],
                    ),
                  ),

                  // ================= ACTIONS =================
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantForm(
                                docId: docId,
                                existingData: data,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () =>
                            _deletePlant(context, docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ================= FLOATING BUTTON =================
      floatingActionButton: showAddButton
          ? FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlantForm(),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  // ================= SMALL INFO ROW =================
  Widget _infoRow(String label, String value,
      [Color color = Colors.white70]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}