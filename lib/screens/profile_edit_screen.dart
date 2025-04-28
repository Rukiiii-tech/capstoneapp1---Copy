import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Controller for the full name input
  final TextEditingController _nameController = TextEditingController();

  // Fetching the current user from Firebase Authentication
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    // Initialize the name controller with the user's full name (if available)
    if (user != null) {
      _nameController.text = user?.displayName ?? "No Name Available";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Function to update the display name
  Future<void> _updateProfile() async {
    try {
      if (user != null && _nameController.text.isNotEmpty) {
        await user!.updateProfile(displayName: _nameController.text);
        await user!.reload(); // Reload the user to get updated data
        setState(() {}); // Rebuild the UI after the update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid name")),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's info
    user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Display the profile picture as a circle avatar
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/avatar.png"),
            ),
            const SizedBox(height: 20),

            // Full Name input field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 20),

            // Email Address field (read-only)
            TextFormField(
              initialValue: user?.email ?? "No email available",
              decoration: const InputDecoration(labelText: "Email Address"),
              enabled: false, // Make email field non-editable
            ),
            const SizedBox(height: 20),

            // Save Changes button
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
