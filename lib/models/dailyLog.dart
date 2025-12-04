import 'package:hive/hive.dart';

part 'dailyLog.g.dart';

@HiveType(typeId: 2)
class DailyLog extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String mood;

  @HiveField(2)
  String bleedingLevel; // none, light, medium, heavy

  @HiveField(3)
  String painLevel; // none, mild, moderate, severe

  @HiveField(4)
  int waterIntake; // total ml

  DailyLog({
    required this.date,
    this.mood = "",
    this.bleedingLevel = "none",
    this.painLevel = "none",
    this.waterIntake = 0,
  });
}
