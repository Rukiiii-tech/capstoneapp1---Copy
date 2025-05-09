import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../models/feeding_schedule.dart';
import '/firestore_service.dart';
import 'choices.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  FeedingSchedule? nextFeeding;
  List<FeedingSchedule> feedingRecords = [];

  String? _selectedBreed;
  int? _selectedYear;
  int? _selectedMonth;

  final TextEditingController _searchController = TextEditingController();

  final List<String> breeds = [
    "Labrador Retriever",
    "Golden Retriever",
    "German Shepherd",
    "Bulldog",
    "Beagle",
    "Poodle",
    "Chihuahua",
    "Shih Tzu",
    "Pomeranian",
    "Rottweiler",
    "Siberian Husky",
    "Dachshund",
    "Great Dane",
    "Doberman",
    "Maltese",
    "Persian Cat",
    "Siamese Cat",
    "Maine Coon",
    "Bengal Cat",
    "Ragdoll",
  ];

  final List<String> petYears = List.generate(11, (index) => index.toString());
  final List<String> petMonths = List.generate(12, (index) => index.toString());

  List<String> filteredBreeds = [];

  @override
  void initState() {
    super.initState();
    filteredBreeds = List.from(breeds);
    _searchController.addListener(() {
      setState(() {
        filteredBreeds =
            breeds
                .where(
                  (breed) => breed.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ),
                )
                .toList();
      });
    });

    if (user != null) {
      _fetchFeedingSchedules(user!.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchFeedingSchedules(String userId) async {
    try {
      final schedules = await FirestoreService().getFeedingSchedules(userId);
      if (mounted) {
        setState(() {
          feedingRecords = schedules;
          feedingRecords.sort((a, b) => a.time.compareTo(b.time));
        });

        for (var schedule in feedingRecords) {
          schedule.checkIfCompleted();
        }

        _removeExpiredFeedings();
      }
    } catch (e) {
      debugPrint('Error fetching feeding schedules: $e');
    }
  }

  void _removeExpiredFeedings() {
    final now = DateTime.now();
    feedingRecords.removeWhere((schedule) => schedule.time.isBefore(now));
  }

  void _setFeedingSchedule() async {
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not authenticated.")));
      return;
    }

    if (_selectedBreed == null ||
        _selectedYear == null ||
        _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select breed and age first")),
      );
      return;
    }

    try {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );

      if (date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time == null) return;

      final label = await _askForLabel();
      if (label == null || label.isEmpty) return;

      final measurement = await _askForMeasurement();
      if (measurement == null || measurement.isEmpty) return;

      final selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final isDuplicate = await FirestoreService().isDuplicateSchedule(
        userId: user!.uid,
        time: selectedDateTime,
        label: label.trim(),
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This schedule already exists.")),
        );
        return;
      }

      final newSchedule = FeedingSchedule(
        userId: user!.uid,
        time: selectedDateTime,
        label: label.trim(),
        measurement: measurement.trim(),
        breed: _selectedBreed!,
        ageYears: _selectedYear!.toString(),
        ageMonths: _selectedMonth!.toString(),
      );

      await FirestoreService().createFeedingSchedule(newSchedule);

      if (mounted) {
        setState(() {
          nextFeeding = newSchedule;
          feedingRecords.add(newSchedule);
          feedingRecords.sort((a, b) => a.time.compareTo(b.time));
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feeding schedule created successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating feeding schedule: $e")),
      );
    }
  }

  Future<String?> _askForLabel() async {
    String label = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Feeding Label'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g., breakfast'),
            onChanged: (value) => label = value.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (label.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a feeding label"),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, label);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askForMeasurement() async {
    String input = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Measurement'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g., 200'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => input = value.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (input.isEmpty || double.tryParse(input) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid number"),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, input);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _triggerServo() async {
    final uri = Uri.parse("http://192.168.16.150/servo"); //For Servo Connection
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Servo triggered successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to trigger servo: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to ESP8266: $e")),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text("Are you sure you want to Log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (_) => false,
                    );
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChoiceScreen()),
            );
          },
        ),
        title: const Text("Manual Feeding Schedule"),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Breed Type:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: false),
              items: breeds,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: const InputDecoration(
                  labelText: "Select Breed",
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (value) => setState(() => _selectedBreed = value),
              selectedItem: _selectedBreed,
            ),
            const SizedBox(height: 16),
            const Text(
              "Age of Pet:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownSearch<String>(
                    popupProps: const PopupProps.menu(showSearchBox: false),
                    items: petYears,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: const InputDecoration(
                        labelText: "Years",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    onChanged:
                        (value) => setState(
                          () => _selectedYear = int.tryParse(value!),
                        ),
                    selectedItem: _selectedYear?.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownSearch<String>(
                    popupProps: const PopupProps.menu(showSearchBox: false),
                    items: petMonths,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: const InputDecoration(
                        labelText: "Months",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    onChanged:
                        (value) => setState(
                          () => _selectedMonth = int.tryParse(value!),
                        ),
                    selectedItem: _selectedMonth?.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setFeedingSchedule,
              child: const Text("Set Feeding Schedule"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _triggerServo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Trigger Servo"),
            ),
            const SizedBox(height: 16),
            const Text(
              'Feeding Records',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: feedingRecords.length,
                itemBuilder: (context, index) {
                  final schedule = feedingRecords[index];
                  return FeedingScheduleCard(schedule: schedule);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
