import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
// 🔴 IMPORTANT: Change this path to match your actual file location
import './Screens/travel_options_screen.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc";
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _sourceCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();

  LatLng? _sourceLocation;
  LatLng? _destinationLocation;
  String _sourceName = "";
  String _destName = "";

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (query.length < 3) return [];
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&key=$apiKey');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK') {
          final List results = data['results'];
          return results.map((p) => {
            'name': p['name'],
            'lat': p['geometry']['location']['lat'],
            'lng': p['geometry']['location']['lng'],
          }).toList();
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
    return [];
  }

  Future<void> _processTravelRequest() async {
    if (_sourceLocation == null || _destinationLocation == null) return;

    // Save both Source and Destination Lat/Long to Firestore
    await _db.collection('user_travel_requests').add({
      'source_name': _sourceName,
      'source_lat': _sourceLocation!.latitude,
      'source_lng': _sourceLocation!.longitude,
      'dest_name': _destName,
      'dest_lat': _destinationLocation!.latitude,
      'dest_lng': _destinationLocation!.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Navigate and pass data to the separate page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TravelOptionsScreen(
          sourceName: _sourceName,
          destName: _destName,
          sourceLat: _sourceLocation!.latitude,
          sourceLng: _sourceLocation!.longitude,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(flex: 1, child: GoogleMap(initialCameraPosition: CameraPosition(target: LatLng(18.5204, 73.8567), zoom: 12))),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSearch(_sourceCtrl, "Source", Colors.green),
                  const SizedBox(height: 10),
                  _buildSearch(_destCtrl, "Destination", Colors.red),
                  const Spacer(),
                  ElevatedButton(onPressed: _processTravelRequest, child: const Text("PROCEED TO MODES")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(TextEditingController ctrl, String label, Color color) {
    return TypeAheadField<Map<String, dynamic>>(
      controller: ctrl,
      builder: (context, controller, focusNode) => TextField(controller: controller, focusNode: focusNode, decoration: InputDecoration(labelText: label, prefixIcon: Icon(Icons.location_on, color: color))),
      suggestionsCallback: _searchPlaces,
      itemBuilder: (context, s) => ListTile(title: Text(s['name'])),
      onSelected: (s) {
        setState(() {
          if (ctrl == _sourceCtrl) { _sourceLocation = LatLng(s['lat'], s['lng']); _sourceName = s['name']; }
          else { _destinationLocation = LatLng(s['lat'], s['lng']); _destName = s['name']; }
          ctrl.text = s['name'];
        });
      },
    );
  }
}