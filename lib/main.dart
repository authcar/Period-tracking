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
  
  await Hive.openBox('periods'); // database box

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

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Demo Hive")),
      body: Center(child: Text("Halo! Hive sudah jalan.")),
    );
  }
}