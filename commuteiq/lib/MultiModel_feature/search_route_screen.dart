import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firestore support
import 'journey_result_screen.dart';

class SearchRouteScreen extends StatefulWidget {
  const SearchRouteScreen({super.key});

  @override
  State<SearchRouteScreen> createState() => _SearchRouteScreenState();
}

class _SearchRouteScreenState extends State<SearchRouteScreen> {
  static const String apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc";

  final TextEditingController _destCtrl = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Firestore instance

  LatLng? _destination;
  String _destName = "";
  List<Map<String, dynamic>> _matchedMetroSchedules = [];

  /// Fetches suggestions from Google Places API
  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (query.length < 2) return [];

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&key=$apiKey');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        
        if (data['status'] == 'OK') {
          final List results = data['results'];
          return results.map((p) => {
                'name': p['name'],
                'address': p['formatted_address'],
                'lat': p['geometry']['location']['lat'],
                'lng': p['geometry']['location']['lng'],
              }).toList();
        } else {
          debugPrint("Google API Status: ${data['status']}. Using Mock Hubs.");
          return _getMockHubs(query);
        }
      }
    } catch (e) {
      debugPrint("Error: $e. Using Mock Hubs.");
      return _getMockHubs(query);
    }
    return [];
  }

  /// ✅ Checks Firestore for matching Metro Schedules from 'train_schedules'
  Future<void> _checkFirestoreForMetro(String stationName) async {
    try {
      QuerySnapshot schedules = await _db.collection('train_schedules').get();
      List<Map<String, dynamic>> foundStops = [];

      for (var doc in schedules.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('stops')) {
          List<dynamic> stops = data['stops'];
          
          for (var stop in stops) {
            // Check if user's destination matches a station in our Firestore data
            if (stop['station_name'].toString().toLowerCase().contains(stationName.toLowerCase())) {
              foundStops.add({
                'train_id': doc.id, 
                'arrival': stop['arrival_time'],
                'departure': stop['departure_time'],
                'station': stop['station_name']
              });
            }
          }
        }
      }

      setState(() {
        _matchedMetroSchedules = foundStops;
      });
    } catch (e) {
      debugPrint("Firestore Error: $e");
    }
  }

  /// Mock Data for Simulation (Multi-modal hubs in Pune)
  List<Map<String, dynamic>> _getMockHubs(String query) {
    final List<Map<String, dynamic>> hubs = [
      {'name': 'Mangalwar Peth (RTO)', 'address': 'Pune Metro Aqua Line', 'lat': 18.5280, 'lng': 73.8620},
      {'name': 'Pune Railway Station', 'address': 'Pune Metro Aqua Line', 'lat': 18.5289, 'lng': 73.8730},
      {'name': 'Ruby Hall Clinic', 'address': 'Pune Metro Aqua Line', 'lat': 18.5320, 'lng': 73.8780},
      {'name': 'Shivajinagar Metro Station', 'address': 'Pune, Maharashtra', 'lat': 18.5312, 'lng': 73.8553},
    ];
    return hubs.where((h) => h['name'].toLowerCase().contains(query.toLowerCase())).toList();
  }

  void _goToJourney() {
    if (_destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination from the list")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JourneyResultScreen(
          destination: _destination!,
          destinationName: _destName,
          // ✅ Passing the retrieved schedules to the next screen
          metroSchedules: _matchedMetroSchedules, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulate Journey'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Multimodal Trip Planner",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Integrating Metro (Firestore), Bus, and Walking."),
            const SizedBox(height: 24),
            
            TypeAheadField<Map<String, dynamic>>(
              controller: _destCtrl,
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "Enter Destination",
                  hintText: "e.g. Ruby Hall Clinic",
                  prefixIcon: const Icon(Icons.train, color: Colors.blueAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              suggestionsCallback: _searchPlaces,
              itemBuilder: (context, suggestion) => ListTile(
                leading: const Icon(Icons.location_on, color: Colors.redAccent),
                title: Text(suggestion['name']),
                subtitle: Text(suggestion['address'], maxLines: 1),
              ),
              onSelected: (suggestion) async {
                setState(() {
                  _destName = suggestion['name'];
                  _destination = LatLng(suggestion['lat'], suggestion['lng']);
                  _destCtrl.text = suggestion['name'];
                });
                
                // Immediately check Firestore for live Metro schedules
                await _checkFirestoreForMetro(suggestion['name']);
                
                FocusScope.of(context).unfocus();
              },
            ),

            if (_matchedMetroSchedules.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "🚇 Metro Schedule Found!", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
              ),
              Text(
                "Route: ${_matchedMetroSchedules.first['train_id']} | Arriving: ${_matchedMetroSchedules.first['arrival']}"
              ),
            ],
            
            const Spacer(), 
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _goToJourney,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("GENERATE MULTIMODAL TOKEN", style: TextStyle(fontSize: 16, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}