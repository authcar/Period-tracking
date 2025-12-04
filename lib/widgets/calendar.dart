import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
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
    
    final settingsBox = Hive.box('settingsBox');
    final periodLength = settingsBox.get(0)?.averagePeriodLength ?? 5;
    
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => _selectedDay != null && _isSameDay(_selectedDay!, day),
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
  }

  Widget _buildDayCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
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
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
          ),
        ),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelectedDayInfo() {
    final dayKey = _selectedDay!.toIso8601String().substring(0, 10);
    final dailyLog = dailyLogBox.get(dayKey);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 8),
            if (dailyLog != null) ...[
              if (dailyLog.mood.isNotEmpty)
                Text('Mood: ${dailyLog.mood}'),
              if (dailyLog.bleedingLevel != 'none')
                Text('Bleeding: ${dailyLog.bleedingLevel}'),
              if (dailyLog.painLevel != 'none')
                Text('Pain: ${dailyLog.painLevel}'),
              if (dailyLog.waterIntake > 0)
                Text('Water: ${dailyLog.waterIntake} ml'),
            ] else
              const Text('No log for this day'),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime day) {
    final dayKey = day.toIso8601String().substring(0, 10);
    final dailyLog = dailyLogBox.get(dayKey);
    
    // You can add a bottom sheet or dialog here for more detailed day info
    // For now, the info is shown in the card below the calendar
  }
}