import 'package:hive/hive.dart';

part 'userSettings.g.dart';

@HiveType(typeId: 3)
class UserSettings extends HiveObject {
  @HiveField(0)
  int averageCycleLength;

  @HiveField(1)
  int averagePeriodLength;

  UserSettings({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
  });
}
