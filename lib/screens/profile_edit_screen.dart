import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Ensure this is correctly imported

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEmailVisible = false;
  bool _isPasswordChanged = false;
  bool _isEmailChanged = false;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _emailController.text = user?.email ?? "No Email Available";
      // Fetch user details from Firestore
      _fetchUserProfile();
    }
  }

  // Fetch user profile details from Firestore
  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['fullName'] ?? 'No Name Available';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading user profile")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      if (user != null && _nameController.text.isNotEmpty) {
        // Update display name in Firebase Auth
        await user!.updateDisplayName(_nameController.text);

        // Check if password is changed and update
        if (_isPasswordChanged && _passwordController.text.isNotEmpty) {
          await user!.updatePassword(_passwordController.text);
        }

        // Check if email is changed and update
        if (_isEmailChanged && _emailController.text.isNotEmpty) {
          await user!.updateEmail(_emailController.text);
        }

        // Update user data in Firestore (no gender or birthday update)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
              'fullName': _nameController.text,
              'email': _emailController.text,
            });

        // Reload user to get the updated profile
        await user!.reload();
        setState(() {
          user = FirebaseAuth.instance.currentUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid name")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
    }
  }

  // Function to log out the user
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error logging out")));
    }
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          // Settings Icon Button
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            iconSize: 35, // Increased icon size for mobile
            onPressed: () {
              // Open settings menu or show options
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Log out?"),
                      content: const Text("Are you sure you want to Log out?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                            _logout(); // Call logout function
                          },
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name field with larger text
            TextFormField(
              controller: _nameController,
              style: TextStyle(fontSize: 18), // Larger font size
              decoration: const InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(fontSize: 18), // Larger label size
              ),
            ),
            const SizedBox(height: 18),

            // Optional: Email change section with larger text
            SwitchListTile(
              title: Text(
                'Change Email',
                style: TextStyle(fontSize: 18), // Larger text
              ),
              value: _isEmailVisible,
              onChanged: (bool value) {
                setState(() {
                  _isEmailVisible = value;
                  if (!value)
                    _isEmailChanged = false; // Reset email change flag
                });
              },
            ),
            if (_isEmailVisible)
              TextFormField(
                controller: _emailController,
                style: TextStyle(fontSize: 18), // Larger font size
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  labelStyle: TextStyle(fontSize: 18), // Larger label size
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (email) {
                  _isEmailChanged =
                      true; // Set the flag to indicate email change
                },
              ),
            const SizedBox(height: 20),

            // Optional: Password change section with larger text
            SwitchListTile(
              title: Text(
                'Change Password',
                style: TextStyle(fontSize: 18), // Larger text
              ),
              value: _isPasswordVisible,
              onChanged: (bool value) {
                setState(() {
                  _isPasswordVisible = value;
                  if (!value)
                    _isPasswordChanged = false; // Reset password change flag
                });
              },
            ),
            if (_isPasswordVisible)
              TextFormField(
                controller: _passwordController,
                style: TextStyle(fontSize: 18), // Larger font size
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(fontSize: 18), // Larger label size
                ),
                onChanged: (password) {
                  _isPasswordChanged =
                      true; // Set the flag to indicate password change
                },
              ),
            const SizedBox(height: 20),

            // Save Changes Button with larger text
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 18), // Larger text for the button
              ),
            ),
          ],
        ),
      ),
    );
  }
}
