import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/firestore_service.dart';
import '../models/feeding_schedule.dart';
import 'login_screen.dart'; // Import LoginScreen for redirection

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Check if the user already exists
        final existingUser = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(email);

        if (existingUser.isNotEmpty) {
          // If the email is already in use, navigate to the login screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered. Please log in.'),
            ),
          );
          // Navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ), // Redirect to LoginScreen
          );
          return;
        }

        // Create a new user if no existing user is found
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Get the created user from FirebaseAuth
        User? user = userCredential.user;

        if (user != null) {
          // Create the user profile
          await FirestoreService().createUserProfile(user, fullName);

          // Optionally: Create an initial feeding schedule after signup (you can adjust this logic)
          final feedingSchedule = FeedingSchedule(
            userId: user.uid,
            time: DateTime.now(),
            label: 'Breakfast',
            measurement: '200g',
            breed: 'Labrador Retriever',
            age: '1 - 15',
          );

          await FirestoreService().createFeedingSchedule(feedingSchedule);

          // After successful sign-up, show a success message and navigate to the login screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in.'),
            ),
          );

          // Navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ), // Redirect to LoginScreen
          );
        }
      } catch (e) {
        // Handle errors like invalid email format, weak password, etc.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your full name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  if (!RegExp(
                    r"^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$",
                  ).hasMatch(value)) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a password";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _signUp, child: const Text("Sign Up")),

              // Button to redirect back to Login screen
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navigate to the LoginScreen directly
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("Already have an account? Sign In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
