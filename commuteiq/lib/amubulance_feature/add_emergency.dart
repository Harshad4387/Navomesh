import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class AmbulanceEmergencyScreen extends StatefulWidget {
  const AmbulanceEmergencyScreen({super.key});

  @override
  State<AmbulanceEmergencyScreen> createState() => _AmbulanceEmergencyScreenState();
}

class _AmbulanceEmergencyScreenState extends State<AmbulanceEmergencyScreen> {
  final String _apiKey = "YOUR_GOOGLE_MAPS_API_KEY";
  final _sessionToken = const Uuid().v4();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Input State
  String _currentLocationName = "Fetching current location...";
  String _selectedHospital = "Select Destination Hospital";
  bool _isEmergencyActive = false;
  bool _isLoading = false;

  // --- STATIC PUNE HOSPITALS ---
  final List<Map<String, String>> _nearbyHospitals = [
    {"name": "Ruby Hall Clinic", "address": "Sassoon Road, Central Pune"},
    {"name": "Sahyadri Super Speciality", "address": "Deccan Gymkhana"},
    {"name": "Jehangir Hospital", "address": "Near Pune Station"},
    {"name": "Deenanath Mangeshkar Hospital", "address": "Erandwane"},
    {"name": "Noble Hospital", "address": "Hadapsar"},
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _triggerEmergency() async {
    if (_selectedHospital.contains("Select")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a hospital first!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition();
      String ambulanceId = "AMB_PUNE_99"; 

      Map<String, dynamic> emergencyPayload = {
        "ambulance_id": ambulanceId,
        "current_lat": position.latitude,
        "current_lng": position.longitude,
        "source": _currentLocationName,
        "destination": _selectedHospital,
        "is_emergency": true,
        "status": "In Transit",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      await _dbRef.update({
        "ambulances/$ambulanceId": emergencyPayload,
        "emergency_logs/${DateTime.now().millisecondsSinceEpoch}": emergencyPayload,
      });

      setState(() {
        _isEmergencyActive = true;
        _isLoading = false;
      });

      _showEmergencySuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      print("Firebase Error: $e");
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() => _currentLocationName = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F2),
      appBar: AppBar(
        title: const Text("Ambulance SOS Response", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildLocationInputCard(),
            const SizedBox(height: 30),
            if (!_isEmergencyActive) _buildSOSAction() else _buildActiveStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          _inputTile(Icons.my_location, "Your Current Location", _currentLocationName, Colors.blue, null),
          const Divider(height: 30),
          _inputTile(Icons.local_hospital, "Target Hospital", _selectedHospital, Colors.red, () => _showHospitalSearch()),
        ],
      ),
    );
  }

  Widget _buildSOSAction() {
    return Column(
      children: [
        const Text("EMERGENCY PROTOCOL", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isLoading ? null : _triggerEmergency,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 10)],
            ),
            child: Center(
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 50),
                      Text("SEND SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text("Quick Select Nearby Hospitals", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: _nearbyHospitals.take(3).map((h) => ActionChip(
            label: Text(h['name']!),
            onPressed: () => setState(() => _selectedHospital = h['name']!),
          )).toList(),
        )
      ],
    );
  }

  Widget _buildActiveStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 15),
              Expanded(
                child: Text("SOS ACTIVE: Heading to $_selectedHospital", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          const Text("Traffic signals on this route are being prioritized.", style: TextStyle(color: Colors.white70, fontSize: 12))
        ],
      ),
    );
  }

  void _showHospitalSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Hospital", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: _nearbyHospitals.length,
                itemBuilder: (context, index) {
                  final h = _nearbyHospitals[index];
                  return ListTile(
                    leading: const Icon(Icons.local_hospital, color: Colors.red),
                    title: Text(h['name']!),
                    subtitle: Text(h['address']!),
                    onTap: () {
                      setState(() => _selectedHospital = h['name']!);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputTile(IconData icon, String label, String value, Color color, VoidCallback? onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showEmergencySuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SOS Broadcasted"),
        content: Text("Emergency entry added to Realtime Database. Route to $_selectedHospital is now being optimized."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }
}