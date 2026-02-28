import 'dart:convert';
import 'dart:ui' as ui;
import 'package:commuteiq/Grouping_feature/nearby_page.dart';
import 'package:commuteiq/auth/register_screen.dart';
import 'package:commuteiq/cascade_feature/disruption_cascade_screen.dart';
import 'package:commuteiq/metrosync/metrosync.dart';
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

  Future<BitmapDescriptor> _getBitmapDescriptorFromIcon(IconData iconData, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);
    const double iconSize = 45.0;

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
      BitmapDescriptor metroMarkerIcon = await _getBitmapDescriptorFromIcon(
          MetroIcon.train, const ui.Color.fromARGB(255, 169, 8, 123));

      QuerySnapshot snapshot = await _db.collection('MetroLocations').get();

      Set<Marker> metroMarkers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['latitude'], data['longitude']),
          infoWindow: InfoWindow(title: data['name'], snippet: '${data['line'] ?? "Metro"} Line Station'),
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
          return (data['results'] as List).map((p) => {
                'name': p['name'],
                'lat': p['geometry']['location']['lat'],
                'lng': p['geometry']['location']['lng'],
              }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
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

    Navigator.push(context, MaterialPageRoute(builder: (_) => TravelOptionsScreen(
          sourceName: _sourceName,
          destName: _destName,
          sourceLat: _sourceLocation!.latitude,
          sourceLng: _sourceLocation!.longitude,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
        )));
  }

  // Helper to handle navigation to NearbyUsersPage with data validation
  void _navigateToNearbyUsers() {
    if (_destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination first!")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyUsersPage(
          destinationId: "dest_${DateTime.now().millisecondsSinceEpoch}",
          destinationName: _destName,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED PAGES LIST TO INCLUDE NearbyUsersPage AT INDEX 3
    final List<Widget> _pages = [
      _buildMapSearchBody(),
      const DisruptionCascadeScreen(),
      const MetroBookingScreen(),
      _destinationLocation == null 
        ? const Center(child: Text("Please select a destination on the Home tab first"))
        : NearbyUsersPage(
            destinationId: "nav_dest",
            destinationName: _destName,
            destLat: _destinationLocation!.latitude,
            destLng: _destinationLocation!.longitude,
          ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("CommuteIQ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.grey, size: 32),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.person, color: Colors.blueAccent, size: 35),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "CommuteIQ User",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Paid Lift'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.ac_unit_sharp),
              title: const Text('Group Rides'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _navigateToNearbyUsers(); // Navigate with data
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Check if user is tapping Nearby Convoy (Index 3)
          if (index == 3 && _destinationLocation == null) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Select a destination on 'Home' to use Nearby Convoy")),
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Cascade'),
          BottomNavigationBarItem(icon: Icon(Icons.sync_alt), activeIcon: Icon(Icons.sync), label: 'Metro Sync'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Nearby Convoy'),
        ],
      ),
    );
  }

  Widget _buildMapSearchBody() {
    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(18.5204, 73.8567), zoom: 12),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            padding: const EdgeInsets.only(bottom: 120),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    "Where are you going?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildSearch(_sourceCtrl, "Source", Colors.green),
                  const SizedBox(height: 10),
                  _buildSearch(_destCtrl, "Destination", Colors.red),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: _processTravelRequest,
                        child: const Text("PROCEED TO MODES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          )),
      suggestionsCallback: _searchPlaces,
      itemBuilder: (context, s) => ListTile(title: Text(s['name'])),
      onSelected: (s) {
        setState(() {
          final loc = LatLng(s['lat'], s['lng']);
          if (ctrl == _sourceCtrl) {
            _sourceLocation = loc;
            _sourceName = s['name'];
            _markers.add(Marker(
                markerId: const MarkerId('user_source'),
                position: loc,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(title: 'Start: $_sourceName')));
          } else {
            _destinationLocation = loc;
            _destName = s['name'];
            _markers.add(Marker(
                markerId: const MarkerId('user_dest'),
                position: loc,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: 'End: $_destName')));
          }
          ctrl.text = s['name'];
        });
      },
    );
  }
}