import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'journey_result_screen.dart';

class SearchRouteScreen extends StatefulWidget {
  const SearchRouteScreen({super.key});

  @override
  State<SearchRouteScreen> createState() => _SearchRouteScreenState();
}

class _SearchRouteScreenState extends State<SearchRouteScreen> {
  static const String apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc";

  final TextEditingController _destCtrl = TextEditingController();
  LatLng? _destination;
  String _destName = "";

  /// Fetches suggestions (With Mock Fallback for Simulation)
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
          // If API fails (REQUEST_DENIED), use Mock Data for simulation
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

  /// ✅ Mock Data for Simulation (Multi-modal hubs in Pune)
  List<Map<String, dynamic>> _getMockHubs(String query) {
    final List<Map<String, dynamic>> hubs = [
      {'name': 'Shivajinagar Metro Station', 'address': 'Pune, Maharashtra', 'lat': 18.5312, 'lng': 73.8553},
      {'name': 'Pune Railway Station (Bus Stand)', 'address': 'Agarkar Nagar, Pune', 'lat': 18.5289, 'lng': 73.8744},
      {'name': 'Hinjewadi IT Park Phase 1', 'address': 'Maan Road, Pune', 'lat': 18.5913, 'lng': 73.7389},
      {'name': 'Magarpatta South Gate', 'address': 'Hadapsar, Pune', 'lat': 18.5132, 'lng': 73.9242},
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
            const Text("Find the best route combining Metro, Bus, and Lifts."),
            const SizedBox(height: 24),
            
            TypeAheadField<Map<String, dynamic>>(
              controller: _destCtrl,
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "Enter Destination",
                  hintText: "e.g. Metro Station",
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              suggestionsCallback: _searchPlaces,
              itemBuilder: (context, suggestion) => ListTile(
                leading: const Icon(Icons.location_on, color: Colors.redAccent),
                title: Text(suggestion['name']),
                subtitle: Text(suggestion['address'], maxLines: 1),
              ),
              onSelected: (suggestion) {
                setState(() {
                  _destName = suggestion['name'];
                  _destination = LatLng(suggestion['lat'], suggestion['lng']);
                  _destCtrl.text = suggestion['name'];
                });
                FocusScope.of(context).unfocus();
              },
            ),
            
            const Spacer(), // Pushes button to bottom
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _goToJourney,
                icon: const Icon(Icons.route),
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