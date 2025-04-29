import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'profile_edit_screen.dart';
import '../models/feeding_schedule.dart';
import '/firestore_service.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time == null) return;

      final label = await _askForLabel();
      if (label == null || label.trim().isEmpty) return;

      final measurement = await _askForMeasurement();
      if (measurement == null || measurement.trim().isEmpty) return;

      final newSchedule = FeedingSchedule(
        userId: user!.uid,
        time: DateTime(date.year, date.month, date.day, time.hour, time.minute),
        label: label.trim(),
        measurement: measurement.trim(),
        breed: _selectedBreed!,
        ageYears: _selectedYear!.toString(), // Fixed
        ageMonths: _selectedMonth!.toString(), // Fixed
      );

      await FirestoreService().createFeedingSchedule(newSchedule);

      setState(() {
        nextFeeding = newSchedule;
        feedingRecords.add(newSchedule);
      });

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
            onChanged: (value) => label = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, label),
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
            decoration: const InputDecoration(hintText: 'e.g., 200g'),
            onChanged: (value) => input = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, input),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text("Pet Feeding"),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(
                showSearchBox: false,
                fit: FlexFit.loose,
              ),
              items: filteredBreeds,
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
                        (value) =>
                            setState(() => _selectedMonth = int.parse(value!)),
                    selectedItem: _selectedMonth?.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            nextFeeding == null
                ? const Text("No feeding scheduled yet")
                : Text(
                  "Next feeding: ${nextFeeding!.formattedTime()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _setFeedingSchedule,
              child: const Text("Set Feeding Schedule"),
            ),
            const SizedBox(height: 20),
            if (feedingRecords.isNotEmpty) ...[
              Text(
                "Feeding Records",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: feedingRecords.length,
                  itemBuilder: (context, index) {
                    return FeedingScheduleCard(schedule: feedingRecords[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
