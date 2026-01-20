import 'package:flutter/material.dart';
import '../widgets/calendar.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

   Position? _currentPosition; // position? adalah tipe data nullable
  bool _isLoadingLocation = false; //agar UI berubah sesuai kondisi

  Future<void> _showCurrentLocation() async { //Kenapa Future & async? ,Pengambilan lokasi tidak instan, Harus menunggu GPS dan permission, Tidak boleh menghambat UI
  setState(() => _isLoadingLocation = true); 

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled(); // Cek apakah gps aktif
  if (!serviceEnabled) {
    _showSnackBar('Location service is disabled');
    setState(() => _isLoadingLocation = false);
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission(); // Minta izin lokasi
  }

  if (permission == LocationPermission.deniedForever) {
    _showSnackBar('Location permission permanently denied');
    setState(() => _isLoadingLocation = false);
    return; 
  }

  _currentPosition = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high, 
  );

  setState(() => _isLoadingLocation = false); // Perbarui UI setelah mendapatkan lokasi

  _showSnackBar(
    'Lat: ${_currentPosition!.latitude}, '
    'Lng: ${_currentPosition!.longitude}',
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

  void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
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
                  fit: BoxFit.cover,
                ),
              ),
            )
            ,
            SizedBox(height: 12),
            CalendarWidget(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on, color: Colors.pink),
                          SizedBox(width: 8),
                          Text(
                            'Your Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_isLoadingLocation)
                        const Center(child: CircularProgressIndicator())
                      else if (_currentPosition != null) ...[
                        Text('Latitude  : ${_currentPosition!.latitude}'),
                        Text('Longitude : ${_currentPosition!.longitude}'),
                      ] else
                        const Text(
                          'Location not detected yet',
                          style: TextStyle(color: Colors.grey),
                        ),

                      const SizedBox(height: 12),

                      
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),

    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 🔹 FAB LOCATION
        FloatingActionButton(
          heroTag: 'locationFab',
          mini: true,
          backgroundColor: const Color.fromARGB(255, 236, 136, 169),
          tooltip: 'Get Location',
          onPressed: _isLoadingLocation ? null : _showCurrentLocation,
          child: _isLoadingLocation
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.my_location, size: 20),
        ),

        const SizedBox(height: 12),

        // 🔹 FAB ABOUT
        FloatingActionButton(
          heroTag: 'aboutFab', // untuk menghindari konflik hero tag
          mini: true,// membuat FAB lebih kecil
          backgroundColor: const Color.fromARGB(255, 236, 136, 169),
          tooltip: 'About App', // teks muncul saat hover
          child: const Icon(Icons.info_outline, size: 20),
          onPressed: () {
            Navigator.pushNamed(context, '/about');
          },
        ),
      ],
    ),


      


    );
  }
}
