import 'package:hive/hive.dart';
import '../models/dailyLog.dart';

class DailyLogService {
  final dailyBox = Hive.box<DailyLog>('dailyLogBox');

  DailyLog getOrCreate(DateTime date) {
    final key = date.toIso8601String().substring(0, 10);

    if (dailyBox.containsKey(key)) {
      return dailyBox.get(key)!;
    } else {
      final log = DailyLog(date: date);
      dailyBox.put(key, log);
      return log;
    }
  }

  void updateMood(DateTime date, String mood) {
    final log = getOrCreate(date);
    log.mood = mood;
    log.save();
  }

  void updateBleeding(DateTime date, String level) {
    final log = getOrCreate(date);
    log.bleedingLevel = level;
    log.save();
  }

  void updatePain(DateTime date, String level) {
    final log = getOrCreate(date);
    log.painLevel = level;
    log.save();
  }

  void addWater(DateTime date, int ml) {
    final log = getOrCreate(date);
    log.waterIntake += ml;
    log.save();
  }
}
