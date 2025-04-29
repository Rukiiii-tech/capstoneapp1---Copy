import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Ensure this is correctly imported
import 'package:intl/intl.dart'; // For formatting date

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String? _selectedGender;

  bool _isPasswordVisible = false;
  bool _isEmailVisible = false;
  bool _isPasswordChanged = false;
  bool _isEmailChanged = false;

  User? user = FirebaseAuth.instance.currentUser;

  final List<String> genders = ["Male", "Female", "Other"];

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user?.displayName ?? "No Name Available";
      _emailController.text = user?.email ?? "No Email Available";
      // Here, we should ideally fetch the birthday and gender from Firestore if stored.
      // For now, we'll assume they are not available, or you can set them to some default value.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      if (user != null && _nameController.text.isNotEmpty) {
        await user!.updateDisplayName(_nameController.text);
        if (_isPasswordChanged && _passwordController.text.isNotEmpty) {
          await user!.updatePassword(_passwordController.text);
        }
        if (_isEmailChanged && _emailController.text.isNotEmpty) {
          await user!.updateEmail(_emailController.text);
        }

        // You can update the user's profile with the gender and birthday here if needed.
        // Firebase doesn't natively support storing these, so you might need Firestore for storing these details.

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _selectBirthday() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _birthdayController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Log Out'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 20),

            // Optional: Email change section
            SwitchListTile(
              title: const Text('Change Email'),
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
                decoration: const InputDecoration(labelText: 'New Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (email) {
                  _isEmailChanged =
                      true; // Set the flag to indicate email change
                },
              ),
            const SizedBox(height: 20),

            // Optional: Password change section
            SwitchListTile(
              title: const Text('Change Password'),
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
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                onChanged: (password) {
                  _isPasswordChanged =
                      true; // Set the flag to indicate password change
                },
              ),
            const SizedBox(height: 20),

            // Birthday field
            TextFormField(
              controller: _birthdayController,
              decoration: const InputDecoration(
                labelText: 'Birthday',
                hintText: 'Select your birthday',
              ),
              readOnly: true,
              onTap: _selectBirthday,
            ),
            const SizedBox(height: 20),

            // Gender selection
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items:
                  genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
              onChanged: (String? newGender) {
                setState(() {
                  _selectedGender = newGender;
                });
              },
            ),
            const SizedBox(height: 20),

            // Save Changes Button
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
