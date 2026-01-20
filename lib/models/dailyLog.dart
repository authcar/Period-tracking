import 'package:hive/hive.dart';

part 'dailyLog.g.dart';

@HiveType(typeId: 2) //typeid unik untuk sambungin ke Hive
class DailyLog extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String mood;

  @HiveField(2)
  String bleedingLevel; 

  @HiveField(3)
  String painLevel; 

  @HiveField(4)
  int waterIntake; 

  DailyLog({
    required this.date,
    this.mood = "",
    this.bleedingLevel = "none",
    this.painLevel = "none",
    this.waterIntake = 0,
  });
}
