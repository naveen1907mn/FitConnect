import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      print("Attempting to sign in with email: $email");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Sign in successful for user: ${userCredential.user?.uid}");
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during sign in: ${e.code} - ${e.message}");
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'configuration-not-found':
          errorMessage = 'Firebase Authentication is not properly configured.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign in';
      }
      throw errorMessage;
    } catch (e) {
      print("General exception during sign in: $e");
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  
  // Register with email and password
  Future<UserCredential?> registerWithEmailPassword(String name, String email, String password) async {
    try {
      print("Attempting to register with email: $email");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("Registration successful for user: ${userCredential.user?.uid}");
      
      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'membership_active': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      print("User profile created in Firestore");
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during registration: ${e.code} - ${e.message}");
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password registration is not enabled.';
          break;
        case 'configuration-not-found':
          errorMessage = 'Firebase Authentication is not properly configured. Please enable Email/Password authentication in the Firebase console.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during registration';
      }
      throw errorMessage;
    } catch (e) {
      print("General exception during registration: $e");
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("User signed out");
      notifyListeners();
    } catch (e) {
      print("Error during sign out: $e");
      throw 'Failed to sign out. Please try again.';
    }
  }
  
  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error getting user profile: $e");
      return null;
    }
  }
} 