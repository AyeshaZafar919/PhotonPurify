import 'package:ayesha_admin/Admin/screens/admin_home_page.dart';
import 'package:ayesha_admin/Client/client_home_page.dart';
import 'package:ayesha_admin/Technician/pages/technician_home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'package:ayesha_admin/Admin/screens/admin_dashboard.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // =====================================================
  // LOGIN LOGIC (UNCHANGED)
  // =====================================================

  void _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      User? user = await _authService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        String? role =
            await _authService.getUserRole(user.uid);

        if (role == "Admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CeruleanThemePage(),
            ),
          );
        } else if (role == "Client") {
          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get();

          String? ownedPlant =
              userDoc["ownedPlant"];

          if (ownedPlant != null &&
              ownedPlant.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ClientHomePage(
                  plantId: ownedPlant,
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage =
                  "No plant assigned to this client!";
            });
          }
        } else if (role == "Technician") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const TechnicianHome(),
            ),
          );
        } else {
          setState(() {
            _errorMessage =
                "User role not assigned!";
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found" ||
          e.code == "invalid-credential") {
        setState(() =>
            _errorMessage =
                "Incorrect Credentials");
      } else if (e.code == "invalid-email") {
        setState(() =>
            _errorMessage =
                "Invalid email format");
      } else if (e.code == "user-disabled") {
        setState(() =>
            _errorMessage =
                "This account has been disabled");
      } else {
        setState(() =>
            _errorMessage =
                "Login failed. Please try again.");
      }
    } catch (e) {
      setState(() =>
          _errorMessage =
              "Login failed. Please try again.");
    } finally {
      setState(() => _loading = false);
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff08111F),
              Color(0xff10233F),
              Color(0xff0B5EA8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),

              child: Container(
                padding:
                    const EdgeInsets.all(24),

                

                child: Column(
                  children: [
                    // Logo
                    Container(
                      height: 120,
                      width: 120,
                      padding:
                          const EdgeInsets.all(
                              16),
                      
                          
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(
                        height: 20),

                    Text(
                      "Photon Purify",
                      style:
                          GoogleFonts.poppins(
                        color:
                            Colors.white,
                        fontSize: 28,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                        height: 8),

                    Text(
                      "Smart Solar Cleaning System",
                      style:
                          GoogleFonts.poppins(
                        color: Colors
                            .white70,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                        height: 28),

                    // Email
                    _fieldBox(
                      child: TextField(
                        controller:
                            emailController,
                        style:
                            const TextStyle(
                          color: Colors
                              .white,
                        ),
                        decoration:
                            InputDecoration(
                          hintText:
                              "Email",
                          hintStyle:
                              const TextStyle(
                            color: Colors
                                .white54,
                          ),
                          prefixIcon:
                              const Icon(
                            Icons.email,
                            color: Colors
                                .cyanAccent,
                          ),
                          border:
                              InputBorder
                                  .none,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 16),

                    // Password
                    _fieldBox(
                      child: TextField(
                        controller:
                            passwordController,
                        obscureText:
                            _obscurePassword,
                        style:
                            const TextStyle(
                          color: Colors
                              .white,
                        ),
                        decoration:
                            InputDecoration(
                          hintText:
                              "Password",
                          hintStyle:
                              const TextStyle(
                            color: Colors
                                .white54,
                          ),
                          prefixIcon:
                              const Icon(
                            Icons.lock,
                            color: Colors
                                .cyanAccent,
                          ),
                          suffixIcon:
                              IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,
                              color: Colors
                                  .white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                          ),
                          border:
                              InputBorder
                                  .none,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 14),

                    if (_errorMessage !=
                        null)
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(12),
                        decoration:
                            BoxDecoration(
                          color: Colors.red
                              .withOpacity(
                                  0.15),
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      14),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              const TextStyle(
                            color: Colors
                                .redAccent,
                          ),
                        ),
                      ),

                    const SizedBox(
                        height: 20),

                    // Login button
                    SizedBox(
                      width:
                          double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _loading
                                ? null
                                : _login,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors
                                  .cyanAccent,
                          foregroundColor:
                              Colors.black,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height:
                                    22,
                                width:
                                    22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.5,
                                  color: Colors
                                      .black,
                                ),
                              )
                            : Text(
                                "LOGIN",
                                style:
                                    GoogleFonts.poppins(
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing:
                                      1.2,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                        height: 12),

                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style:
                            GoogleFonts.poppins(
                          color: Colors
                              .white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // REUSABLE FIELD BOX
  // =====================================================

  Widget _fieldBox({
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: child,
    );
  }
}