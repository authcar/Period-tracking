import 'package:flutter/material.dart';
import '../widgets/calendar.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  Future<void> _showCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog('Error', 'Location service is disabled');
      return;
    }

    // 2. Cek permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showDialog(
        'Permission Denied',
        'Location permission permanently denied',
      );
      return;
    }

    // 3. Ambil posisi
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4. Tampilkan popup
    _showDialog(
      'Your Location',
      'Latitude : ${position.latitude}\n'
      'Longitude: ${position.longitude}',
    );
  }

  // 🔹 Fungsi popup dialog
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Period Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _showCurrentLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            SizedBox(height: 16),
            CalendarWidget(),
          ],
        ),
      ),
    );
  }
}
