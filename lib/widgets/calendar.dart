import 'package:flutter/material.dart';
import 'package:period_tracker/models/userSettings.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menstrual_cycle.dart';
import '../models/dailyLog.dart';
import '../services/periodPrediction.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final menstrualBox = Hive.box<MenstrualCycle>('menstrualDataBox');
  final dailyLogBox = Hive.box<DailyLog>('dailyLogBox');
  final prediction = PeriodPredictionService();

  void _clearSelection() {
    setState(() {
      _selectedDay = null;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  // Check if a date is a period day (from recorded cycles)
  bool _isPeriodDay(DateTime day) {
    for (var cycle in menstrualBox.values) {
      if (_isSameDay(day, cycle.startDate) ||
          _isSameDay(day, cycle.endDate) ||
          (day.isAfter(cycle.startDate) && day.isBefore(cycle.endDate))) {
        return true;
      }
    }
    return false;
  }

  // Check if a date is predicted period
  bool _isPredictedPeriod(DateTime day) {
    final nextPeriod = prediction.predictNextPeriod();
    if (nextPeriod == null) return false;

    final settingsBox = Hive.box<UserSettings>('settingsBox');
    final settings = settingsBox.get(0);
    final periodLength =
        settings?.averagePeriodLength ??
        5; // ?.if null then return null instead of crashing
    //?? if null return 5

    final periodEnd = nextPeriod.add(Duration(days: periodLength - 1));

    return day.isAfter(nextPeriod.subtract(const Duration(days: 1))) &&
        day.isBefore(periodEnd.add(const Duration(days: 1)));
  }

  // Check if a date is in fertile window
  bool _isFertileDay(DateTime day) {
    final fertile = prediction.fertileWindow();
    if (fertile == null) return false;

    return day.isAfter(fertile['start']!.subtract(const Duration(days: 1))) &&
        day.isBefore(fertile['end']!.add(const Duration(days: 1)));
  }

  // Check if a date is ovulation day
  bool _isOvulationDay(DateTime day) {
    final ovulation = prediction.predictOvulation();
    if (ovulation == null) return false;
    return _isSameDay(day, ovulation);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- FUNGSI BARU: START PERIOD ---
  Future<void> _startPeriodHere(DateTime day) async {
    final settingsBox = Hive.box<UserSettings>('settingsBox');
    final settings = settingsBox.get(0);
    final defaultPeriodLength = settings?.averagePeriodLength ?? 5;

    // Hitung end date otomatis
    final endDate = day.add(Duration(days: defaultPeriodLength - 1));

    // Buat cycle baru
    final newCycle = MenstrualCycle(
      startDate: day,
      endDate: endDate,
    );

    // Simpan ke Hive
    await menstrualBox.add(newCycle);

    setState(() {
      // Refresh UI
    });

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Period dimulai ${day.day}/${day.month}/${day.year}\n'
          'Estimasi selesai: ${endDate.day}/${endDate.month}/${endDate.year}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- FUNGSI BARU: EDIT END DATE ---
  Future<void> _editEndDate(DateTime startDay) async {
    // Cari cycle yang cocok
    MenstrualCycle? targetCycle;
    dynamic targetKey;

    for (var key in menstrualBox.keys) {
      final cycle = menstrualBox.get(key);
      if (cycle != null && _isSameDay(cycle.startDate, startDay)) {
        targetCycle = cycle;
        targetKey = key;
        break;
      }
    }

    if (targetCycle == null) return;

    // Tampilkan date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: targetCycle.endDate,
      firstDate: targetCycle.startDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Pilih Tanggal Selesai Period',
    );

    if (pickedDate != null) {
      // Update end date
      targetCycle.endDate = pickedDate;
      await menstrualBox.put(targetKey, targetCycle);

      setState(() {});

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tanggal selesai diupdate ke ${pickedDate.day}/${pickedDate.month}/${pickedDate.year}',
          ),
        ),
      );
    }
  }

  // Fungsi untuk menampilkan konfirmasi hapus
  Future<void> _showDeleteConfirmDialog(DateTime day) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Siklus Menstruasi?'),
          content: const Text(
            'Data siklus menstruasi pada tanggal ini akan dihapus dan warna merah akan hilang.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _removePeriodCycle(day);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi logika penghapusan data dari Hive
  void _removePeriodCycle(DateTime day) {
    dynamic keyToDelete;

    for (var key in menstrualBox.keys) {
      final cycle = menstrualBox.get(key);
      if (cycle != null) {
        if (_isSameDay(day, cycle.startDate) ||
            _isSameDay(day, cycle.endDate) ||
            (day.isAfter(cycle.startDate) && day.isBefore(cycle.endDate))) {
          keyToDelete = key;
          break;
        }
      }
    }

    if (keyToDelete != null) {
      menstrualBox.delete(keyToDelete);

      setState(() {});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Siklus berhasil dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: menstrualBox.listenable(),
      builder: (context, Box<MenstrualCycle> box, _) {
        return Column(
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              // TAMBAHAN: Hilangin tombol 2 weeks
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              selectedDayPredicate: (day) =>
                  _selectedDay != null && _isSameDay(_selectedDay!, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showDayDetails(selectedDay);
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.pink.shade400,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isToday: true);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isSelected: true);
                },
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            _buildLegend(),
            const SizedBox(height: 20),
            // Selected day info
            if (_selectedDay != null) _buildSelectedDayInfo(),
          ],
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    Color? backgroundColor;
    Color textColor = Colors.black;

    if (_isPeriodDay(day)) {
      backgroundColor = Colors.red.shade400;
      textColor = Colors.white;
    } else if (_isPredictedPeriod(day)) {
      backgroundColor = Colors.red.shade100;
    } else if (_isOvulationDay(day)) {
      backgroundColor = Colors.green.shade400;
      textColor = Colors.white;
    } else if (_isFertileDay(day)) {
      backgroundColor = Colors.green.shade100;
    }

    if (isToday && backgroundColor == null) {
      backgroundColor = Colors.blue.shade100;
    }

    if (isSelected) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.pink.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.pink.shade700, width: 2),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: backgroundColor != null ? textColor : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: Text('${day.day}', style: TextStyle(color: textColor)),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(Colors.red.shade400, 'Period'),
          _legendItem(Colors.red.shade100, 'Predicted Period'),
          _legendItem(Colors.green.shade400, 'Ovulation'),
          _legendItem(Colors.green.shade100, 'Fertile Window'),
          _legendItem(Colors.blue.shade100, 'Today'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSelectedDayInfo() {
    // Safety check
    if (_selectedDay == null) return const SizedBox.shrink();

    final dayKey = _selectedDay!.toIso8601String().substring(0, 10);
    final dailyLog = dailyLogBox.get(dayKey);

    // Cek apakah hari ini merah (Period)
    bool isPeriod = _isPeriodDay(_selectedDay!);

    // Cek apakah ini start date dari cycle
    bool isStartDate = false;
    for (var cycle in menstrualBox.values) {
      if (_isSameDay(cycle.startDate, _selectedDay!)) {
        isStartDate = true;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Judul & Tombol Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected: ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _clearSelection,
                  tooltip: 'Clear selection',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- TOMBOL AKSI ---
            // 1. Kalau BELUM period → tampilkan "Start Period Here"
            if (!isPeriod)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startPeriodHere(_selectedDay!),
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Start Period Here'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            // 2. Kalau SUDAH period → tampilkan tombol Edit & Delete
            if (isPeriod) ...[
              Row(
                children: [
                  // Tombol Edit End Date (cuma muncul kalau ini start date)
                  if (isStartDate)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editEndDate(_selectedDay!),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit End'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (isStartDate) const SizedBox(width: 8),
                  
                  // Tombol Delete Cycle
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteConfirmDialog(_selectedDay!),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Log Harian
            if (dailyLog != null) ...[
              const Divider(),
              if (dailyLog.mood.isNotEmpty) Text('Mood: ${dailyLog.mood}'),
              if (dailyLog.bleedingLevel != 'none')
                Text('Bleeding: ${dailyLog.bleedingLevel}'),
              if (dailyLog.painLevel != 'none')
                Text('Pain: ${dailyLog.painLevel}'),
              if (dailyLog.waterIntake > 0)
                Text('Water: ${dailyLog.waterIntake} ml'),
            ] else if (!isPeriod)
              const Text('No log for this day'),

            // Indikator Status Tambahan
            if (isPeriod)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Status: Menstruasi (Period)',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime day) {
    final dayKey = day.toIso8601String().substring(0, 10);
    final dailyLog = dailyLogBox.get(dayKey);
  }
}