import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'), 
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Period Tracker',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'A simple period tracking app to help monitor cycles, '
              'predict fertile windows, and log daily symptoms.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Made with ❤️ by Audrey Theresia'),
          ],
        ),
      ),
    );
  }
}
