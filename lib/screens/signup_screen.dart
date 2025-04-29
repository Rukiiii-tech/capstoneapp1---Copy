import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/firestore_service.dart';
import '../models/feeding_schedule.dart';
import 'login_screen.dart';

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

  String? _selectedGender;
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  List<int> years = List.generate(100, (index) => DateTime.now().year - index);
  List<int> months = List.generate(12, (index) => index + 1);
  List<int> days = [];

  final List<String> genders = ["Male", "Female", "Other"];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _updateDays() {
    if (_selectedYear != null && _selectedMonth != null) {
      int daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
      setState(() {
        days = List.generate(daysInMonth, (index) => index + 1);
        if (_selectedDay != null && _selectedDay! > daysInMonth) {
          _selectedDay = daysInMonth;
        }
      });
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final gender = _selectedGender;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedYear == null ||
          _selectedMonth == null ||
          _selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your complete birthday')),
        );
        return;
      }

      DateTime birthday = DateTime(
        _selectedYear!,
        _selectedMonth!,
        _selectedDay!,
      );

      try {
        // Check if the email is already registered
        final existingUser = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(email);

        if (existingUser.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered. Please log in.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          return;
        }

        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;

        if (user != null) {
          // ✅ Update display name in Firebase Auth
          await user.updateDisplayName(fullName);
          await user.reload(); // Optional, ensures the update takes effect

          // Create user profile in Firestore
          await FirestoreService().createUserProfile(
            user,
            fullName,
            gender: gender,
            birthday: birthday,
          );

          // Create initial feeding schedule for the user
          final feedingSchedule = FeedingSchedule(
            userId: user.uid,
            time: DateTime.now(),
            label: 'Breakfast',
            measurement: '200g',
            breed: 'Labrador Retriever',
            ageYears: '1 - 10',
            ageMonths: '1 - 11',
          );

          await FirestoreService().createFeedingSchedule(feedingSchedule);

          // Show confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in.'),
            ),
          );

          // Navigate to the login screen after account creation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
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
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? "Please enter your full name"
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter your email";
                  if (!RegExp(
                    r"^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$",
                  ).hasMatch(value))
                    return "Please enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter a password";
                  if (value.length < 6)
                    return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: "Gender"),
                items:
                    genders
                        .map(
                          (gender) => DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator:
                    (value) =>
                        value == null ? "Please select your gender" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(labelText: "Year"),
                      items:
                          years
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                          _updateDays();
                        });
                      },
                      validator:
                          (value) => value == null ? 'Select year' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(labelText: "Month"),
                      items:
                          months
                              .map(
                                (month) => DropdownMenuItem(
                                  value: month,
                                  child: Text('$month'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                          _updateDays();
                        });
                      },
                      validator:
                          (value) => value == null ? 'Select month' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDay,
                      decoration: const InputDecoration(labelText: "Day"),
                      items:
                          days
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day,
                                  child: Text('$day'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                      validator: (value) => value == null ? 'Select day' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _signUp, child: const Text("Sign Up")),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
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
