import 'package:flutter/material.dart';
import 'package:gym_app_project/home.dart';
import 'package:gym_app_project/auth/auth_page.dart';
import 'package:gym_app_project/screens/profile.dart';
import 'package:gym_app_project/screens/gym_management.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBUdw3Fmi6MnOq5ucF9nTiM4NLCgwLOn58",
          authDomain: "gymhub-c23fb.firebaseapp.com",
          projectId: "gymhub-c23fb",
          storageBucket: "gymhub-c23fb.firebasestorage.app",
          messagingSenderId: "640391418655",
          appId: "1:640391418655:web:4ef945915f8d3d57ef162a",
          measurementId: "G-8JPHHEXTZ9"
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/gym-management': (context) => const GymManagementScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          return const Homepage();
        }
        
        return const AuthPage();
      },
    );
  }
}


