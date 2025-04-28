import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PushButton extends StatelessWidget {
  final String servoControlUrl;

  // The URL for controlling the servo motor, passed in from parent widget
  const PushButton({Key? key, required this.servoControlUrl}) : super(key: key);

  // Function to send the request to control the servo motor
  Future<void> _controlServoMotor(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(servoControlUrl));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Servo motor activated!')));
      } else {
        throw Exception('Failed to activate the servo motor');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error controlling servo motor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _controlServoMotor(context),
      child: const Text("Activate Servo Motor"),
    );
  }
}
