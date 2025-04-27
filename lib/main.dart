import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Feeding',
      theme: ThemeData(
        fontFamily: 'ComicNeue',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF8B5E3C),
          onPrimary: Colors.white,
          secondary: const Color(0xFFC8AD7F),
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          background: const Color(0xFFFFF8F0),
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(), // NEW: handles user state
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
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // If not logged in
        return const LoginScreen();
      },
    );
  }
}
