import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fitconnect/screens/auth/login_screen.dart';
import 'package:fitconnect/services/auth_service.dart';

void main() async {
  try {
    print("Starting app initialization...");
    WidgetsFlutterBinding.ensureInitialized();
    print("Flutter binding initialized");
    
    // Initialize Firebase with options
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA5uVSsN7vwD3-KTd3G7K53CiP3fgGfWzQ',
        appId: '1:1088795481849:android:b3f8e65fdc360c8cd7b428',
        messagingSenderId: '1088795481849',
        projectId: 'fitconnect-57b27',
        storageBucket: 'fitconnect-57b27.firebasestorage.app',
      ),
    );
    print("Firebase initialized");
    
    // Test Firestore initialization
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('booking').doc('test').set({
        'test': 'test',
        'created_at': FieldValue.serverTimestamp()
      });
      print("Firestore test successful");
    } catch (firestoreError) {
      print("Firestore test failed: $firestoreError");
    }
    
    try {
      await dotenv.load(fileName: ".env");
      print("Environment variables loaded");
    } catch (e) {
      print("Error loading .env file: $e");
      print("Continuing without environment variables");
    }
    
    runApp(const MyApp());
    print("App started");
  } catch (e) {
    print("Error during initialization: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("Building MyApp widget");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'FitConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFF03DAC6),
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
