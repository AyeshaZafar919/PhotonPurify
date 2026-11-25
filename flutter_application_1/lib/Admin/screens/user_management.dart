import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _search = TextEditingController();
  String _filter = "All";

  List<String> plantList = [];

  @override
  void initState() {
    super.initState();
    fetchPlants();
  }

  Future<void> fetchPlants() async {
    try {
      final snapshot = await _firestore.collection("clients").get();
      setState(() {
        plantList = snapshot.docs.map((doc) {
          // using document ID as plant name, adjust if you store name inside field.
          return doc.id;
        }).toList();
      });
    } catch (e) {
      // keep empty list on error, but print for debugging
      debugPrint("Error fetching plants: $e");
    }
  }

  // 🔹 Color mapping for roles
  Color _getRoleColor(String role) {
    switch (role) {
      case "Admin":
        return Colors.red.shade100;
      case "Client":
        return Colors.blue.shade100;
      case "Technician":
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // 🔹 User Actions Menu
  Widget _userMenu(QueryDocumentSnapshot user) {
    final isActive = (user.data() as Map<String, dynamic>)["ustatus"] == "Active";

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      onSelected: (value) async {
        if (value == "toggleStatus") {
          await _firestore.collection("users").doc(user.id).update({
            "ustatus": isActive ? "In-Active" : "Active",
          });

          if (isActive) {
            _showSnack("User disabled", success: false);
          } else {
            _showSnack("User enabled");
          }
        }

        if (value == "view") {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text("User Password"),
                content: Text(
                  (user.data() as Map<String, dynamic>)['password'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              );
            },
          );
        }

        if (value == "edit") {
          Future.microtask(() {
  if (context.mounted) {
    _showUserDialog(context, userDoc: user);
  }
});
        }

        if (value == "delete") {
          try {
            await _firestore.collection("users").doc(user.id).delete();
            if (_auth.currentUser != null && _auth.currentUser!.uid == user.id) {
              // deleting own auth user is risky; we try but it may require recent login
              try {
                await _auth.currentUser!.delete();
              } catch (e) {
                debugPrint("Couldn't delete firebase auth user: $e");
              }
            }
            _showSnack("User deleted", success: false);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "toggleStatus",
          child: Row(
            children: [
              Icon(
                isActive ? Icons.block : Icons.check_circle,
                color: isActive ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(isActive ? "Disable User" : "Enable User"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "view",
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.orange),
              SizedBox(width: 8),
              Text("View Password"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "edit",
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text("Edit User"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text("Delete User"),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens a dialog showing `plantList` with a search field; selecting sets [targetCtrl].
  Future<void> _openPlantPicker(BuildContext context, TextEditingController targetCtrl) async {
    final TextEditingController filter = TextEditingController();
    List<String> filtered = List.from(plantList);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          void applyFilter(String f) {
            final q = f.trim().toLowerCase();
            setStateDialog(() {
              if (q.isEmpty) {
                filtered = List.from(plantList);
              } else {
                filtered = plantList.where((p) => p.toLowerCase().contains(q)).toList();
              }
            });
          }

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Plant"),
                IconButton(
                  tooltip: "Refresh list",
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await fetchPlants();
                    applyFilter(filter.text);
                    _showSnack("Plant list refreshed");
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: Column(
                children: [
                  TextField(
                    controller: filter,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search plants",
                    ),
                    onChanged: (v) => applyFilter(v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              plantList.isEmpty ? "No plants found." : "No matches.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              return ListTile(
                                title: Text(p),
                                onTap: () {
                                  targetCtrl.text = p;
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          );
        });
      },
    );
  }

  void _showUserDialog(BuildContext context, {QueryDocumentSnapshot? userDoc}) {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController unameCtrl = TextEditingController(text: userDoc?['uname'] ?? '');
  final TextEditingController uemailCtrl = TextEditingController(text: userDoc?['uemail'] ?? '');
  final TextEditingController passwordCtrl = TextEditingController(text: userDoc?['password'] ?? '');
  final TextEditingController contactCtrl = TextEditingController(text: userDoc?['contact'] ?? '');
  final TextEditingController specializationCtrl = TextEditingController(text: userDoc?['specialization'] ?? '');
  final TextEditingController ownedPlantCtrl = TextEditingController(text: userDoc?['ownedPlant'] ?? '');

  String role = userDoc?['urole'] ?? 'Client';

  Future<List<String>> _getPlantNames() async {
    final snapshot = await FirebaseFirestore.instance.collection("clients").get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(userDoc == null ? "Add User" : "Edit User"),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- Name ---
                    TextFormField(
                      controller: unameCtrl,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "⚠️ Name is required";
                        if (RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                            return "⚠️ Plant name cannot be only numbers";
                          }
                        if (v.trim().length < 3) return "⚠️ Name must be at least 3 characters";
                        return null;
                      },
                    ),

                    // --- Email ---
                    TextFormField(
                      controller: uemailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "⚠️ Email is required";
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(v.trim())) return "⚠️ Enter a valid email";
                        return null;
                      },
                    ),

                    // --- Password ---
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (v) {
                        if (userDoc == null) {
                          // Add mode → password required
                          if (v == null || v.isEmpty) return "⚠️ Password is required";
                          if (v.length < 6) return "⚠️ Min 6 characters";
                        } else {
                          // Edit mode → optional
                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return "⚠️ Min 6 characters if changing password";
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // --- Role Dropdown ---
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: "Role"),
                      items: ["Client", "Technician", "Admin"]
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() => role = v);
                      },
                    ),

                    if (role == "Technician") ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: specializationCtrl,
                        decoration: const InputDecoration(labelText: "Specialization"),
                        validator: (v) {
                          if (role == "Technician" && (v == null || v.trim().isEmpty)) {
                            return "⚠️ Specialization required for Technician";
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 8),

                    // --- Contact ---
                    TextFormField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(labelText: "Contact"),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "⚠️ Contact is required";
                        if (!RegExp(r'^[0-9]+$').hasMatch(v)) return "⚠️ Digits only";
                        if (v.length < 10) return "⚠️ Min 10 digits";
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // --- Owned Plant (Clients only) ---
                    if (role == "Client")
                      FutureBuilder<List<String>>(
                        future: _getPlantNames(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final plants = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            value: ownedPlantCtrl.text.isNotEmpty ? ownedPlantCtrl.text : null,
                            decoration: const InputDecoration(labelText: "Owned Plant"),
                            items: plants.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) => ownedPlantCtrl.text = val ?? '',
                            validator: (v) {
                              if (role == "Client" && (v == null || v.isEmpty)) {
                                return "⚠️ Please select a plant";
                              }
                              return null;
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  try {
                    if (userDoc == null) {
                      // ADD
                      final cred = await _auth.createUserWithEmailAndPassword(
                        email: uemailCtrl.text.trim(),
                        password: passwordCtrl.text.trim(),
                      );

                      await _firestore.collection("users").doc(cred.user!.uid).set({
                        "uname": unameCtrl.text.trim(),
                        "uemail": uemailCtrl.text.trim(),
                        "password": passwordCtrl.text.trim(),
                        "urole": role,
                        "specialization": role == "Technician" ? specializationCtrl.text.trim() : null,
                        "contact": contactCtrl.text.trim(),
                        "ownedPlant": role == "Client" ? ownedPlantCtrl.text.trim() : null,
                        "ustatus": "Active",
                        "availability": true,
                        "createdAt": FieldValue.serverTimestamp(),
                      });
                    } else {
                      // UPDATE
                      await _firestore.collection("users").doc(userDoc.id).update({
                        "uname": unameCtrl.text.trim(),
                        "uemail": uemailCtrl.text.trim(),
                        "password": passwordCtrl.text.trim(),
                        "urole": role,
                        "specialization": role == "Technician" ? specializationCtrl.text.trim() : null,
                        "ownedPlant": role == "Client" ? ownedPlantCtrl.text.trim() : null,
                        "contact": contactCtrl.text.trim(),
                        "updatedAt": FieldValue.serverTimestamp(),
                      });
                    }

                    Navigator.pop(context);
                    _showSnack(userDoc == null ? "✅ User added successfully" : "✅ User updated successfully");
                  } catch (e) {
                    debugPrint("Error: $e");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: Text(userDoc == null ? "Add User" : "Save Changes"),
              ),
            ],
          );
        },
      );
    },
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          final users = snapshot.data!.docs;

          final filteredUsers = users.where((doc) {
            final name = (doc.data() as Map<String, dynamic>)["uname"].toString().toLowerCase();
            final role = (doc.data() as Map<String, dynamic>)["urole"].toString();
            final searchQuery = _search.text.toLowerCase();

            final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);
            final matchesFilter = _filter == "All" || role == _filter;

            return matchesSearch && matchesFilter;
          }).toList();

          // Stats
          final totalUsers = users.length;
          final activeUsers = users.where((doc) => (doc.data() as Map<String, dynamic>)["ustatus"] == "Active").length;
          final inactiveUsers = users.where((doc) => (doc.data() as Map<String, dynamic>)["ustatus"] == "In-Active").length;
          final clientUsers = users.where((doc) => (doc.data() as Map<String, dynamic>)["urole"] == "Client").length;
          final adminUsers = users.where((doc) => (doc.data() as Map<String, dynamic>)["urole"] == "Admin").length;
          final technicianUsers = users.where((doc) => (doc.data() as Map<String, dynamic>)["urole"] == "Technician").length;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _header(),

                const SizedBox(height: 12),
                // 🔹 Stats Cards
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  //margin: const EdgeInsets.symmetric(horizontal: 12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6, // total stats
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 🔥 3 cards per row
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95, // adjust height
                  ),
                  itemBuilder: (context, index) {
                    final stats = [
                      ["Total Users", totalUsers, Icons.people, Colors.purple],
                      ["Active", activeUsers, Icons.check_circle, Colors.green],
                      ["Inactive", inactiveUsers, Icons.block, Colors.red],
                      ["Clients", clientUsers, Icons.person, Colors.blue],
                      [
                        "Admins",
                        adminUsers,
                        Icons.admin_panel_settings,
                        Colors.orange,
                      ],
                      ["Tech", technicianUsers, Icons.engineering, Colors.teal],
                    ];

                    final item = stats[index];

                    return _modernStatCard(
                      item[0] as String,
                      item[1] as int,
                      item[2] as IconData,
                      item[3] as Color,
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 🔹 Search + Filter + FAB
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Search users...",
                            hintStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(width: 10),

                      PopupMenuButton<String>(
                        color: const Color(0xFF0F172A),
                        onSelected: (v) => setState(() => _filter = v),
                        itemBuilder: (_) =>
                            ['All', 'Admin', 'Client', 'Technician']
                                .map(
                                  (f) => PopupMenuItem(
                                    value: f,
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),

                      const SizedBox(width: 10),

                      FloatingActionButton.small(
                        backgroundColor: Colors.cyanAccent,
                        onPressed: () => _showUserDialog(context),
                        child: const Icon(Icons.add, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🔹 User List
                ListView.builder(
                  itemCount: filteredUsers.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _modernUserTile(filteredUsers[index]);
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _modernStatCard(
  String title,
  int count,
  IconData icon,
  Color color,
) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.9, end: 1),
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) {
      return Transform.scale(
        scale: scale,
        child: Container(
          //width: 135, // smaller width
          padding: const EdgeInsets.all(12), // reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 18, // smaller icon
              ),

              const SizedBox(height: 8),

              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18, // smaller number
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11, // smaller title
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _modernUserTile(QueryDocumentSnapshot user) {
  final data = user.data() as Map<String, dynamic>;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
          child: Text(
            (data["uname"] ?? "U")[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data["uname"] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data["uemail"] ?? '',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 4),
              Text(
                "Role: ${data["urole"]} • Status: ${data["ustatus"]}",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),

        _userMenu(user),
      ],
    ),
  );
}

Widget _header() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF0F172A)],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.people, color: Colors.cyanAccent),
          SizedBox(width: 10),
          Text(
            "USER CONTROL CENTER",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
}


}
