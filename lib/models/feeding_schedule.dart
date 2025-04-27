import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

// Feeding Schedule model
//April 27
class FeedingSchedule {
  final String userId;
  final DateTime time;
  final String label;
  final String measurement;
  final String breed;

  FeedingSchedule({
    required this.userId,
    required this.time,
    required this.label,
    required this.measurement,
    required this.breed,
  });

  // Convert the FeedingSchedule object to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    print("Converting schedule to map");
    Map<String, dynamic> map = {
      'userId': userId,
      'time': time.toIso8601String(),
      'label': label,
      'measurement': measurement,
      'breed': breed,
    };
    print("Map created: $map");
    return map;
  }

  // Create a FeedingSchedule object from Firestore data
  factory FeedingSchedule.fromMap(Map<String, dynamic> map) {
    return FeedingSchedule(
      userId: map['userId'] ?? '',
      time: DateTime.parse(map['time']),
      label: map['label'] ?? '',
      measurement: map['measurement'] ?? '',
      breed: map['breed'] ?? '',
    );
  }

  // Format the time as a user-friendly string using the intl package
  String formattedTime() {
    final DateFormat formatter = DateFormat('MM/dd/yyyy hh:mm a');
    return formatter.format(time);
  }
}

// Feeding Schedule Card Widget to display each feeding schedule
class FeedingScheduleCard extends StatelessWidget {
  final FeedingSchedule schedule;

  const FeedingScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(schedule.label),
        subtitle: Text(
          "${schedule.formattedTime()}\nBreed: ${schedule.breed}\nMeasurement: ${schedule.measurement}",
        ),
      ),
    );
  }
}
