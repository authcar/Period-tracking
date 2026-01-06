import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/userSettings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settingsBox = Hive.box<UserSettings>('settingsBox');
  late TextEditingController cycleLengthController;
  late TextEditingController periodLengthController;

  @override
  void initState() {
    super.initState();
    final settings = settingsBox.get(0) ?? UserSettings();
    
    cycleLengthController = TextEditingController(
      text: settings.averageCycleLength.toString(),
    );
    periodLengthController = TextEditingController(
      text: settings.averagePeriodLength.toString(),
    );
  }

  @override
  void dispose() {
    cycleLengthController.dispose();
    periodLengthController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final cycleLength = int.tryParse(cycleLengthController.text);
    final periodLength = int.tryParse(periodLengthController.text);

    if (cycleLength == null || cycleLength <= 0) {
      _showError('Cycle length harus berupa angka positif');
      return;
    }

    if (periodLength == null || periodLength <= 0) {
      _showError('Period length harus berupa angka positif');
      return;
    }

    if (periodLength > cycleLength) {
      _showError('Period length tidak boleh lebih panjang dari cycle length');
      return;
    }

    final settings = UserSettings(
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
    );

    settingsBox.put(0, settings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings berhasil disimpan!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Siklus Menstruasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Average Cycle Length
            TextField(
              controller: cycleLengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Average Cycle Length (days)',
                helperText: 'Rata-rata panjang siklus (dari hari pertama mens ke hari pertama mens berikutnya)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(height: 20),
            
            // Average Period Length
            TextField(
              controller: periodLengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Average Period Length (days)',
                helperText: 'Rata-rata lama menstruasi (berapa hari Anda mens)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
            ),
            const SizedBox(height: 32),
            
            // Tombol Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Simpan Pengaturan',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info tambahan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pengaturan ini digunakan untuk memprediksi siklus menstruasi Anda ke depan. Rata-rata siklus normal adalah 21-35 hari.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}