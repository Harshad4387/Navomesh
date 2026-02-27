import 'dart:convert';
import 'dart:ui' as ui; // ✅ Added for marker generation
import 'package:commuteiq/cascade_feature/disruption_cascade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import './Screens/travel_options_screen.dart';
import 'package:metro_icons/metro_icons.dart';

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

  int _selectedIndex = 0;
  
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchMetroLocations();
  }

  // ✅ Updated for a smaller icon size (45.0)
  Future<BitmapDescriptor> _getBitmapDescriptorFromIcon(IconData iconData, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);

    const double iconSize = 45.0; // Reduced from 100.0

    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        fontSize: iconSize, 
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(iconSize.toInt(), iconSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _fetchMetroLocations() async {
    try {
      // ✅ Custom color applied to the smaller icon
      BitmapDescriptor metroMarkerIcon = await _getBitmapDescriptorFromIcon(
        MetroIcon.train, 
        const ui.Color.fromARGB(255, 169, 8, 123) 
      );

      QuerySnapshot snapshot = await _db.collection('MetroLocations').get();
      
      Set<Marker> metroMarkers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        final double lat = data['latitude'];
        final double lng = data['longitude'];
        final String name = data['name'];
        final String line = data['line'] ?? "Metro";

        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: '$line Line Station',
          ),
          icon: metroMarkerIcon,
        );
      }).toSet();

      setState(() {
        _markers.addAll(metroMarkers);
      });
    } catch (e) {
      debugPrint("Error fetching metro markers: $e");
    }
  }

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

    await _db.collection('user_travel_requests').add({
      'source_name': _sourceName,
      'source_lat': _sourceLocation!.latitude,
      'source_lng': _sourceLocation!.longitude,
      'dest_name': _destName,
      'dest_lat': _destinationLocation!.latitude,
      'dest_lng': _destinationLocation!.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

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
    final List<Widget> _pages = [
      _buildMapSearchBody(),
      const DisruptionCascadeScreen(),
      const Center(child: Text("Profile & Settings")),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Cascade'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMapSearchBody() {
    return Column(
      children: [
        Expanded(
          flex: 1, 
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(18.5204, 73.8567), 
              zoom: 12
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
          )
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("Where are you going?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildSearch(_sourceCtrl, "Source", Colors.green),
                const SizedBox(height: 10),
                _buildSearch(_destCtrl, "Destination", Colors.red),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: _processTravelRequest, 
                    child: const Text("PROCEED TO MODES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1))
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch(TextEditingController ctrl, String label, Color color) {
    return TypeAheadField<Map<String, dynamic>>(
      controller: ctrl,
      builder: (context, controller, focusNode) => TextField(
        controller: controller, 
        focusNode: focusNode, 
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(Icons.location_on, color: color),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)
          ),
        )
      ),
      suggestionsCallback: _searchPlaces,
      itemBuilder: (context, s) => ListTile(title: Text(s['name'])),
      onSelected: (s) {
        setState(() {
          if (ctrl == _sourceCtrl) { 
            _sourceLocation = LatLng(s['lat'], s['lng']); 
            _sourceName = s['name']; 
            
            _markers.add(Marker(
              markerId: const MarkerId('user_source'),
              position: _sourceLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: 'Start: $_sourceName'),
            ));
          }
          else { 
            _destinationLocation = LatLng(s['lat'], s['lng']); 
            _destName = s['name']; 

            _markers.add(Marker(
              markerId: const MarkerId('user_dest'),
              position: _destinationLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: 'End: $_destName'),
            ));
          }
          ctrl.text = s['name'];
        });
      },
    );
  }
}