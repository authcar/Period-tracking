import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dailyLog.dart';

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
  bool hasUnsavedChanges = false; // 🔹 Track perubahan yang belum disimpan

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  @override
  void didUpdateWidget(DailyLoggingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload log kalau tanggal berubah
    if (oldWidget.selectedDay != widget.selectedDay) {
      _loadLog();
    }
  }

  void _loadLog() {
    dayKey = widget.selectedDay.toIso8601String().substring(0, 10);

    // Load dari Hive atau buat baru
    final existingLog = widget.dailyLogBox.get(dayKey);

    if (existingLog != null) {
      // Clone data dari Hive agar tidak mengubah data asli sebelum save
      log = DailyLog(
        date: existingLog.date,
        mood: existingLog.mood,
        bleedingLevel: existingLog.bleedingLevel,
        painLevel: existingLog.painLevel,
        waterIntake: existingLog.waterIntake,
      );
    } else {
      log = DailyLog(date: widget.selectedDay);
    }

    hasUnsavedChanges = false;
    setState(() {});
  }

  void _markChanged() {
    setState(() {
      hasUnsavedChanges = true;
    });
  }

  void _save() {
    widget.dailyLogBox.put(dayKey, log);

    print('SAVED DAILY LOG');
    print('KEY: $dayKey');
    print('VALUE: $log'); // Untuk debugging hive
    print('ALL DATA: ${widget.dailyLogBox.toMap()}');

    setState(() {
      hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Changes Saved ${widget.selectedDay.day}/${widget.selectedDay.month}/${widget.selectedDay.year}',
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🔹 Konfirmasi jika keluar tanpa save
  Future<bool> _confirmDiscard() async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('changes not saved'),
        content: const Text(
          'there are unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'discard changes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 247, 228, 238),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan indikator unsaved changes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Logging', style: TextStyle(fontSize: 16)),
                if (hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'unsaved changes',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  // HP kecil → vertikal
                  return Column(
                    children: [
                      _moodTracker(),
                      const SizedBox(height: 16),
                      _painLevel(),
                    ],
                  );
                } else {
                  // HP besar / tablet
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _moodTracker()),
                      const SizedBox(width: 12),
                      Expanded(child: _painLevel()),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  return Column(
                    children: [
                      _bleedingLevel(),
                      const SizedBox(height: 16),
                      _waterIntake(),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _bleedingLevel()),
                      const SizedBox(width: 12),
                      Expanded(child: _waterIntake()),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // 🔹 TOMBOL SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasUnsavedChanges
                    ? _save
                    : null, // Disable kalau tidak ada perubahan
                icon: const Icon(Icons.save),
                label: Text(
                  hasUnsavedChanges ? 'save changes' : 'no changes to save',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasUnsavedChanges
                      ? const Color.fromARGB(255, 75, 149, 213)
                      : const Color.fromARGB(255, 139, 137, 137),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 😊 MOOD TRACKER
  Widget _moodTracker() {
    final moods = ['ヽ( `д´*)ノ', '(´• ω •`)', '	(╥﹏╥)', '	(x_x)', '	╮(︶︿︶)╭'];

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
                setState(() {
                  log.mood = mood;
                });
                _markChanged();
              },
              selectedColor: Colors.pink.shade100,
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
              label: Text(
                e.key,
                style: TextStyle(
                  color: log.bleedingLevel == e.key
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              selected: log.bleedingLevel == e.key,
              selectedColor: e.value,
              backgroundColor: Colors.grey.shade100,
              onSelected: (_) {
                setState(() {
                  log.bleedingLevel = e.key;
                });
                _markChanged();
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
              label: Text(
                e.key,
                style: TextStyle(
                  color: log.painLevel == e.key ? Colors.white : Colors.black87,
                ),
              ),
              selected: log.painLevel == e.key,
              selectedColor: e.value,
              backgroundColor: Colors.grey.shade100,
              onSelected: (_) {
                setState(() {
                  log.painLevel = e.key;
                });
                _markChanged();
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
        Row(
          children: [
            const Text('Water Intake'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${log.waterIntake} ml',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 17, 90, 162),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _waterButton('+250 ml', 250),
            _waterButton('+500 ml', 500),
            _waterButton('+1 L', 1000),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  log.waterIntake = 0;
                });
                _markChanged();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade300),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _waterButton(String label, int amount) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          log.waterIntake += amount;
        });
        _markChanged();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 20, 96, 158),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
