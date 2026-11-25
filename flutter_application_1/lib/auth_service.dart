import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login User
Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      // ✅ Pass FirebaseAuthException directly to UI
      throw e;
      //print("🔥 Firebase error code: ${e.code}");
      //print("🔥 Firebase error message: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }


  // Fetch Role
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc['urole'];
    }
    return null;
  }

  // Logout User
  Future<void> logout() async {
    await _auth.signOut();
  }
}
