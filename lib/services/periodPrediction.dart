import 'package:hive/hive.dart';
import '../models/menstrual_cycle.dart';
import '../models/userSettings.dart';

class PeriodPredictionService {
  final menstrualBox = Hive.box<MenstrualCycle>('menstrualDataBox');
  final settingsBox = Hive.box<UserSettings>('settingsBox');

  /// Ambil data cycle terakhir user
  MenstrualCycle? getLatestCycle() {
    if (menstrualBox.isEmpty) return null;
    return menstrualBox.values.last;
  }

  /// Prediksi tanggal menstruasi berikutnya
  DateTime? predictNextPeriod() {
    final last = getLatestCycle();
    final settings = settingsBox.get(0);

    if (last == null || settings == null) return null;

    return last.startDate.add(
      Duration(days: settings.averageCycleLength),
    );
  }

  /// Ovulation = startDate + 14 hari
  DateTime? predictOvulation() {
    final next = predictNextPeriod();
    if (next == null) return null;
    return next.subtract(const Duration(days: 14));
  }

  /// Fertile window = ovulation - 5 sampai ovulation + 1
  Map<String, DateTime>? fertileWindow() {
    final ovulation = predictOvulation();
    if (ovulation == null) return null;

    return {
      "start": ovulation.subtract(const Duration(days: 5)),
      "end": ovulation.add(const Duration(days: 1)),
    };
  }
}
