import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home.dart';
import 'models/menstrual_cycle.dart';
import 'models/dailyLog.dart';
import 'models/userSettings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(MenstrualCycleAdapter());
  Hive.registerAdapter(DailyLogAdapter());
  Hive.registerAdapter(UserSettingsAdapter());

  await Hive.openBox<MenstrualCycle>('menstrualDataBox');
  await Hive.openBox<DailyLog>('dailyLogBox');
  await Hive.openBox<UserSettings>('settingsBox');

  final settingsBox = Hive.box<UserSettings>('settingsBox');
  if (settingsBox.isEmpty) { // "Kalau laci kosong (belum ada isinya)... taruh setting default
    settingsBox.put(0, UserSettings());
  }
  
  runApp( MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Period Tracker',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HomeScreen(),
    );
  }
}

