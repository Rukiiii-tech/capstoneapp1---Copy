import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'automatic_home_screen.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart'; // Ensure this import is added

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  // Log out user and navigate to the LoginScreen
  void _logOut(BuildContext context) async {
    try {
      // Close any open modals before logging out
      Navigator.pop(context);

      // Sign out the user from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear the navigation stack and go to LoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Removes all previous routes
      );
    } catch (error) {
      // Show an error if log out fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Choose Home Screen'),
        backgroundColor: colorScheme.primary,
        actions: [
          // Profile icon button that navigates to Profile Edit Screen
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 30, // Increased icon size
            onPressed: () {
              // Navigate to the Profile Edit Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
          ),
          // Notification icon button
          IconButton(
            icon: const Icon(Icons.notifications),
            iconSize: 30, // Increased icon size
            onPressed: () {
              // Handle notification icon tap
              print('Notification icon tapped!');
              // You can navigate to a notifications screen or show a dialog here.
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heading text
            Text(
              'Choose Your Type of Feeding',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 30),
            // Button for Manual Set Feeding Schedule
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: colorScheme.primary,
              ),
              child: Text(
                "Manual Set Feeding Schedule",
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 20),
            // Button for Automatic Set Feeding Schedule
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AutomaticHomeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: colorScheme.primary,
              ),
              child: Text(
                "Automatic Set Feeding Schedule",
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
