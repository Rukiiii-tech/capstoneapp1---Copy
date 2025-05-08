import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'choices.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  // Check if the user is already logged in when the screen loads
  void _checkIfLoggedIn() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // If the user is logged in, navigate to the ChoiceScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChoiceScreen()),
        );
      }
    });
  }

  // Sign in function
  void signIn() {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      setState(() => _isLoading = false);
      return;
    }

    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .then((_) {
          // On successful login, navigate to ChoiceScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChoiceScreen()),
          );
        })
        .catchError((error) {
          String errorMessage = "Login failed.";
          if (error is FirebaseAuthException) {
            switch (error.code) {
              case 'user-not-found':
                errorMessage = "No user found for that email.";
                break;
              case 'wrong-password':
                errorMessage = "Incorrect password.";
                break;
              case 'invalid-email':
                errorMessage = "Invalid email format.";
                break;
              case 'too-many-requests':
                errorMessage = "Too many attempts. Try again later.";
                break;
            }
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        })
        .whenComplete(() {
          setState(() => _isLoading = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        // Center the contents of the screen
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            // Allow scrolling if keyboard appears
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Ensures the column is centered
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Welcome\nBack",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Username / Email",
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter your email' : null,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Please enter your password'
                                : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        signIn();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: colorScheme.primary,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              "Login",
                              style: TextStyle(color: colorScheme.onPrimary),
                            ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text("New to Pet Feeding? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
