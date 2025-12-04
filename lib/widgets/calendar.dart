import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calendar")),
      body: Center(
        child: Text(
          "Here will be your calendar view",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
