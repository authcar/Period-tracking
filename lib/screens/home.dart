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
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            /// 1) Add fake period entry for testing
            final entry = MenstrualCycle(
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 4)),
            );

            await menstrualBox.add(entry);

            /// 2) Calculate prediction
            final next = prediction.predictNextPeriod();
            final ovulation = prediction.predictOvulation();
            final fertile = prediction.fertileWindow();

            print("Next period: $next");
            print("Ovulation: $ovulation");
            print("Fertile Window: $fertile");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Added cycle!\nNext: ${next?.toLocal()}\nOvulation: ${ovulation?.toLocal()}",
                ),
              ),
            );
          },
          child: const Text("Add Cycle + Predict"),
        ),
      ),
    );
  }
}
