import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/menstrual_cycle.dart';
import '../services/periodPrediction.dart';
import '../widgets/calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final prediction = PeriodPredictionService();
  final menstrualBox = Hive.box<MenstrualCycle>('menstrualDataBox');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Period Tracker")),
      body: SingleChildScrollView(  // Biar bisa di-scroll
        child: Column(
          children: [
            // Tombol test (opsional, bisa dihapus nanti)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  final entry = MenstrualCycle(
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 4)),
                  );
                  await menstrualBox.add(entry);
                  
                  setState(() {}); // Refresh tampilan
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cycle added!")),
                  );
                },
                child: const Text("Add Test Cycle"),
              ),
            ),
            
            // Calendar widget kamu
            const CalendarWidget(),
          ],
        ),
      ),
    );
  }
}