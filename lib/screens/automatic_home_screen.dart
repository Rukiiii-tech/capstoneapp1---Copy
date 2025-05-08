import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'choices.dart'; // Assuming ChoiceScreen is located here
import '../models/feeding_schedule.dart';
import '/firestore_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AutomaticHomeScreen extends StatefulWidget {
  const AutomaticHomeScreen({super.key});

  @override
  State<AutomaticHomeScreen> createState() => _AutomaticHomeScreenState();
}

class _AutomaticHomeScreenState extends State<AutomaticHomeScreen> {
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

  final List<String> petYears = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
  ];

  final List<String> petMonths = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
  ];

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

    _fetchFeedingSchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchFeedingSchedules() async {
    final schedules = await FirestoreService().getFeedingSchedules(user!.uid);
    setState(() {
      feedingRecords = schedules;
    });
  }

  void _setFeedingSchedule() async {
    if (_selectedBreed == null ||
        _selectedYear == null ||
        _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select breed and age first")),
      );
      return;
    }

    try {
      DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );

      if (date == null) return;

      final label = await _askForLabel();
      if (label == null || label.isEmpty) return;

      final measurementString = await _askForMeasurement();
      if (measurementString == null || measurementString.isEmpty) return;

      double? totalGrams = double.tryParse(measurementString);
      if (totalGrams == null || totalGrams <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid number for measurement"),
          ),
        );
        return;
      }

      double portionPerMeal = totalGrams / 3;

      List<TimeOfDay> feedingTimes = [
        TimeOfDay(hour: 7, minute: 0),
        TimeOfDay(hour: 12, minute: 0),
        TimeOfDay(hour: 18, minute: 0),
      ];

      for (int i = 0; i < feedingTimes.length; i++) {
        final time = feedingTimes[i];
        final mealTime =
            i == 0
                ? "Breakfast"
                : i == 1
                ? "Lunch"
                : "Dinner";
        final portion = portionPerMeal;

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
            const SnackBar(
              content: Text(
                "A feeding schedule with the same time and label already exists.",
              ),
            ),
          );
          return;
        }

        final newSchedule = FeedingSchedule(
          userId: user!.uid,
          time: selectedDateTime,
          label: "$label - $mealTime (${portion.toStringAsFixed(0)}g)",
          measurement: portion.toStringAsFixed(0),
          breed: _selectedBreed!,
          ageYears: _selectedYear!.toString(),
          ageMonths: _selectedMonth!.toString(),
        );

        await FirestoreService().createFeedingSchedule(newSchedule);

        setState(() {
          feedingRecords.add(newSchedule);
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
            decoration: const InputDecoration(hintText: 'e.g., Meal Plan'),
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
          title: const Text('Enter Total Measurement (grams)'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g., 300'),
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

  // Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Logged out successfully")));
    // Navigate to login screen or wherever needed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChoiceScreen()),
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
            // Navigate to the ChoiceScreen when back button is pressed
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChoiceScreen()),
            );
          },
        ),
        title: const Text("Automatic Pet Feeding"),
        backgroundColor: colorScheme.primary,
        actions: [
          // Settings button with logout functionality
          IconButton(
            icon: const Icon(Icons.exit_to_app),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        (value) =>
                            setState(() => _selectedYear = int.parse(value!)),
                    selectedItem: _selectedYear?.toString(),
                  ),
                ),
                const SizedBox(width: 16),
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
                        (value) =>
                            setState(() => _selectedMonth = int.parse(value!)),
                    selectedItem: _selectedMonth?.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setFeedingSchedule,
              child: const Text("Set Automatic Feeding Schedule"),
            ),
            const SizedBox(height: 20),
            Text(
              'Feeding Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  feedingRecords.isEmpty
                      ? Center(
                        child: Text(
                          'No feeding records available.',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: feedingRecords.length,
                        itemBuilder: (context, index) {
                          final feeding = feedingRecords[index];
                          final timeFormatted = DateFormat(
                            'hh:mm a',
                          ).format(feeding.time);
                          final dateFormatted = DateFormat(
                            'yyyy-MM-dd',
                          ).format(feeding.time);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              title: Text(
                                feeding.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Breed: ${feeding.breed}"),
                                  Text("Measurement: ${feeding.measurement}g"),
                                  Text("Date: $dateFormatted"),
                                  Text("Time: $timeFormatted"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
