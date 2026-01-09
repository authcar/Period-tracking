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
      body: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              height: 130, // 👈 Lebih kecil
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/banner.png'),
                  fit: BoxFit.fill,
                ),
              ),
            )
            ,
            SizedBox(height: 12),
            CalendarWidget(),

            // Height: 80px (lebih hemat space)
            
          ],
        ),
      ),
    );
  }
}
