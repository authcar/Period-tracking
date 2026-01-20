import 'package:flutter/material.dart';
import 'package:period_tracker/models/userSettings.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menstrual_cycle.dart';
import '../models/dailyLog.dart';
import '../services/periodPrediction.dart';
import '../widgets/daily_logging_card.dart';

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

  bool _hasPeriodInSameMonth(DateTime day) {
    for (var cycle in menstrualBox.values) {
      if (cycle.startDate.year == day.year &&
          cycle.startDate.month == day.month) {
        return true;
      }
    }
    return false;
  }

  // --- FUNGSI BARU: START PERIOD ---
  Future<void> _startPeriodHere(DateTime day) async {
    final settingsBox = Hive.box<UserSettings>('settingsBox');
    final settings = settingsBox.get(0);
    final defaultPeriodLength = settings?.averagePeriodLength ?? 5;

    // Hitung end date otomatis
    final endDate = day.add(Duration(days: defaultPeriodLength - 1));

    // Buat cycle baru
    final newCycle = MenstrualCycle(startDate: day, endDate: endDate);

    // Simpan ke Hive
    await menstrualBox.add(newCycle);

    setState(() {
      // Refresh UI
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Period started on ${day.day}/${day.month}/${day.year}\n'
          'Estimated end date ${endDate.day}/${endDate.month}/${endDate.year}',
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
          title: const Text('Delete Period Cycle?'),
          content: const Text(
            'the period cycle associated with this day will be permanently deleted. Are you sure you want to proceed?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      ).showSnackBar(const SnackBar(content: Text('period cycle deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea (
      child: ValueListenableBuilder( // ui rebuild tiap data berubah di hive
        valueListenable: menstrualBox.listenable(),
        builder: (context, Box<MenstrualCycle> box, _) {
          return Column(
            children: [
              // Calendar
              TableCalendar(
                rowHeight: 42,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                // TAMBAHAN: Hilangin tombol 2 weeks
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},

                headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(
                  fontSize: 19,
                ),
              ),

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
                  cellMargin: const EdgeInsets.all(4),
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
              const SizedBox(height: 16),
              // Legend
              _buildLegend(),
              const SizedBox(height: 16),
              // Selected day info
              if (_selectedDay != null) _buildSelectedDayInfo(),
            ],
          );
        },
      ) 
    );
  }
  //ui builders untuk tiap hari
  Widget _buildDayCell(
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    Color? backgroundColor;
    Color textColor = Colors.black; 
    bool isPeriod = _isPeriodDay(day);
    bool isPredicted = _isPredictedPeriod(day);

    if (isPeriod) {
      backgroundColor = const Color.fromARGB(255, 250, 101, 143);
      textColor = Colors.white;
    } else if (isPredicted) {
      backgroundColor = const Color(0xFFFFDAE0);
    } else if (_isOvulationDay(day)) {
      backgroundColor = const Color.fromARGB(255, 215, 180, 255);
      textColor = Colors.white;
    } else if (_isFertileDay(day)) {
      backgroundColor = const Color(0xFFE0F5DD);
    }

    if (isToday && backgroundColor == null) {
      backgroundColor = const Color(0xFFBDE0FE);
    }

    // ❤️ PERIOD = HEART SHAPE
    if (isPeriod || isPredicted) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(38, 38),
              painter: HeartPainter(color: backgroundColor!),
            ),

            if (isSelected) // tambahin border kalo selected
              CustomPaint(
                size: const Size(42, 42),
                painter: HeartPainter(color: Colors.pink.shade700),
              ),

            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
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
        spacing: 20, 
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(const Color.fromARGB(255, 250, 101, 143), 'Period'),
          _legendItem(Colors.red.shade100, 'Predicted Period'),
          _legendItem(const Color.fromARGB(255, 215, 180, 255), 'Ovulation'),
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

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan tombol close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected: ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                      style: const TextStyle(
                        fontSize: 16,
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

                // Tombol Start Period (kalau belum period)
                if (!isPeriod && !_hasPeriodInSameMonth(_selectedDay!))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startPeriodHere(_selectedDay!),
                      icon: const Icon(Icons.nights_stay_rounded),
                      label: const Text('Start Period'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 250, 101, 143),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                // kalau sudah ada period di bulan ini
                if (!isPeriod && _hasPeriodInSameMonth(_selectedDay!))
                  Container( 
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200), 
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You already have a period logged this month.', //warning orange border
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tombol Edit & Delete (kalau sudah period
                if (isPeriod) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (isStartDate) 
                          ElevatedButton.icon(
                            onPressed: () => _editEndDate(_selectedDay!),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit End'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 107, 169, 222),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showDeleteConfirmDialog(_selectedDay!),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 220, 93, 91),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1),

                ],

                // Pesan kalau bukan period
                if (!isPeriod && !_hasPeriodInSameMonth(_selectedDay!))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mood, bleeding, and pain logs are only available during your period.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 🔹 DAILY LOGGING CARD (muncul di bawah card pertama saat period)
                if (isPeriod)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: DailyLoggingCard(
                      selectedDay: _selectedDay!,
                      dailyLogBox: dailyLogBox,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDayDetails(DateTime day) {
    final dayKey = day.toIso8601String().substring(0, 10);
    final dailyLog = dailyLogBox.get(dayKey);
  }
}

class HeartPainter extends CustomPainter {
  final Color color;

  HeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;

    double w = size.width;
    double h = size.height;

    Path path = Path();

    // Start from bottom tip
    path.moveTo(w * 0.5, h);

    // Left side of heart
    path.cubicTo(
      w * 0.2, h * 0.8,
      0, h * 0.6,
      0, h * 0.4,
    );

    // Left bump
    path.cubicTo(
      0, h * 0.15,
      w * 0.2, 0,
      w * 0.35, h * 0.1,
    );

    // Top center
    path.cubicTo(
      w * 0.45, h * 0.15,
      w * 0.5, h * 0.2,
      w * 0.5, h * 0.3,
    );

    // Right side mirrored
    path.cubicTo(
      w * 0.5, h * 0.2,
      w * 0.55, h * 0.15,
      w * 0.65, h * 0.1,
    );

    // Right bump
    path.cubicTo(
      w * 0.8, 0,
      w, h * 0.15,
      w, h * 0.4,
    );

    // Right side of heart
    path.cubicTo(
      w, h * 0.6,
      w * 0.8, h * 0.8,
      w * 0.5, h,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
