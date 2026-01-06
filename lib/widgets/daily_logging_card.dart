import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dailyLog.dart';
import 'package:flutter/material.dart';

class DailyLoggingCard extends StatefulWidget {
  final DateTime selectedDay;
  final Box<DailyLog> dailyLogBox;

  const DailyLoggingCard({
    super.key,
    required this.selectedDay,
    required this.dailyLogBox,
  });

  @override
  State<DailyLoggingCard> createState() => _DailyLoggingCardState();
}

class _DailyLoggingCardState extends State<DailyLoggingCard> {
  late DailyLog log;
  late String dayKey;

  @override
  void initState() {
    super.initState();
    dayKey = widget.selectedDay.toIso8601String().substring(0, 10);
    log = widget.dailyLogBox.get(dayKey) ??
    DailyLog(
      date: widget.selectedDay,
    );
  }

  void _save() {
    widget.dailyLogBox.put(dayKey, log);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Logging',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _moodTracker(),
            const SizedBox(height: 16),

            _bleedingLevel(),
            const SizedBox(height: 16),

            _painLevel(),
            const SizedBox(height: 16),

            _waterIntake(),
          ],
        ),
      ),
    );
  }

  // 😊 MOOD TRACKER
  Widget _moodTracker() {
    final moods = ['😊', '😐', '😔', '😢', '😠', '🥱'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mood'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: moods.map((mood) {
            return ChoiceChip(
              label: Text(mood, style: const TextStyle(fontSize: 20)),
              selected: log.mood == mood,
              onSelected: (_) {
                log.mood = mood;
                _save();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🩸 BLEEDING LEVEL
  Widget _bleedingLevel() {
    final levels = {
      'none': Colors.grey.shade300,
      'light': Colors.red.shade100,
      'medium': Colors.red.shade300,
      'heavy': Colors.red.shade600,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bleeding Level'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: levels.entries.map((e) {
            return ChoiceChip(
              label: Text(e.key),
              selected: log.bleedingLevel == e.key,
              selectedColor: e.value,
              onSelected: (_) {
                log.bleedingLevel = e.key;
                _save();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 😖 PAIN LEVEL
  Widget _painLevel() {
    final levels = {
      'none': Colors.grey.shade300,
      'mild': Colors.orange.shade200,
      'moderate': Colors.orange.shade400,
      'severe': Colors.red.shade500,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pain Level'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: levels.entries.map((e) {
            return ChoiceChip(
              label: Text(e.key),
              selected: log.painLevel == e.key,
              selectedColor: e.value,
              onSelected: (_) {
                log.painLevel = e.key;
                _save();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 💧 WATER INTAKE
  Widget _waterIntake() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Water Intake: ${log.waterIntake} ml'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _waterButton('+250 ml', 250),
            _waterButton('+500 ml', 500),
            _waterButton('+1 L', 1000),
            TextButton(
              onPressed: () {
                log.waterIntake = 0;
                _save();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _waterButton(String label, int amount) {
    return ElevatedButton(
      onPressed: () {
        log.waterIntake += amount;
        _save();
      },
      child: Text(label),
    );
  }
}
