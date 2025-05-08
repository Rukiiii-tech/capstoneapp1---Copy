import 'package:flutter/material.dart';
import 'choices.dart'; // Import the correct ChoiceScreen file.

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToChoiceScreen();
  }

  // This method handles navigation to ChoiceScreen after a short delay
  Future<void> _navigateToChoiceScreen() async {
    // Add a delay to show the welcome screen for 2-3 seconds
    await Future.delayed(const Duration(seconds: 2));

    // After the delay, navigate to the ChoiceScreen and remove WelcomeScreen from the stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ChoiceScreen()),
      (route) =>
          false, // Remove all previous routes, ensuring the WelcomeScreen doesn't stay in the stack
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets, // Add your custom icon here
              size: 100,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome to Pet Feeding App!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
