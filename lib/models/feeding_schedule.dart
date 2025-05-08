import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedingSchedule {
  final String userId;
  final DateTime time;
  final String label;
  final String measurement;
  final String breed;
  final String ageYears;
  final String ageMonths;
  bool completed = false; // Added field to track if feeding is completed

  FeedingSchedule({
    required this.userId,
    required this.time,
    required this.label,
    required this.measurement,
    required this.breed,
    required this.ageYears,
    required this.ageMonths,
  });

  // Convert FeedingSchedule to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'time': time.toIso8601String(),
      'label': label,
      'measurement': measurement,
      'breed': breed,
      'ageYears': ageYears,
      'ageMonths': ageMonths,
      'completed': completed, // Add completed to Firestore map
    };
  }

  // Factory constructor to create FeedingSchedule from Firestore data
  factory FeedingSchedule.fromMap(Map<String, dynamic> map) {
    return FeedingSchedule(
      userId: map['userId'] ?? '',
      time: DateTime.parse(map['time']),
      label: map['label'] ?? '',
      measurement: map['measurement'] ?? '',
      breed: map['breed'] ?? '',
      ageYears: map['ageYears']?.toString() ?? '0',
      ageMonths: map['ageMonths']?.toString() ?? '0',
    )..completed = map['completed'] ?? false;
  }

  // Format the time using intl package
  String formattedTime() {
    final DateFormat formatter = DateFormat('MM/dd/yyyy hh:mm a');
    return formatter.format(time);
  }

  // Helper to format age nicely
  String get formattedAge => "$ageYears year(s), $ageMonths month(s)";

  String? get id => null;

  // Method to check if feeding is completed
  void checkIfCompleted() {
    if (time.isBefore(DateTime.now())) {
      completed = true; // Mark as completed if time is in the past
    }
  }
}

// Card UI Widget to display a feeding schedule
class FeedingScheduleCard extends StatelessWidget {
  final FeedingSchedule schedule;

  const FeedingScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color:
          schedule.completed
              ? Colors.green.shade100
              : null, // Change color if completed
      child: ListTile(
        title: Text(schedule.label),
        subtitle: Text(
          "${schedule.formattedTime()}\n"
          "Breed: ${schedule.breed}\n"
          "Age: ${schedule.formattedAge}\n"
          "Measurement: ${schedule.measurement}",
        ),
      ),
    );
  }
}
