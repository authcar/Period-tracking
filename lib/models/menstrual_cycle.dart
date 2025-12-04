import 'package:hive/hive.dart';

part 'menstrual_cycle.g.dart';

@HiveType(typeId: 1)
class MenstrualCycle extends HiveObject {
  @HiveField(0)
  DateTime startDate;

  @HiveField(1)
  DateTime endDate;

  MenstrualCycle({
    required this.startDate,
    required this.endDate,
  });

  int get cycleLength => endDate.difference(startDate).inDays + 1;
}
