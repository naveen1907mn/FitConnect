import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:fitconnect/screens/auth/login_screen.dart';
import 'package:fitconnect/services/auth_service.dart';
import 'package:fitconnect/utils/config.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
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
    
    // Initialize AppConfig
    AppConfig.initializeConfig();
    
    runApp(const MyApp());
  } catch (e) {
    // Handle initialization errors
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
