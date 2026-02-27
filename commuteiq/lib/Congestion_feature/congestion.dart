import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;


class KothrudPreShockSimulator extends StatefulWidget {
  const KothrudPreShockSimulator({super.key});


  @override
  State<KothrudPreShockSimulator> createState() => _KothrudPreShockSimulatorState();
}


class _KothrudPreShockSimulatorState extends State<KothrudPreShockSimulator> {
  // 🔴 INJECT YOUR API KEY HERE
  final String _googleApiKey = 'AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc';


  late GoogleMapController mapController;
 
  // Coordinates
  final LatLng kothrudCenter = const LatLng(18.5020, 73.8050);
  final LatLng chandniChowk = const LatLng(18.5042, 73.7820); // Jam Location
  final LatLng kothrudDepot = const LatLng(18.5065, 73.8150); // Start of detour
  final LatLng bavdhanExit = const LatLng(18.5150, 73.7750); // End of detour


  // Simulation State
  double _currentTime = 12.0;
  bool _isCongested = false;
  bool _isLoadingRoute = false;
 
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};


  final String _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
      {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]}
    ]
  ''';


  @override
  void initState() {
    super.initState();
    _setupMonitoringZone();
  }


  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(_darkMapStyle);
  }


  void _setupMonitoringZone() {
    _circles.add(
      Circle(
        circleId: const CircleId('kothrud_zone'),
        center: kothrudCenter,
        radius: 3000,
        fillColor: Colors.blueAccent.withOpacity(0.1),
        strokeColor: Colors.blueAccent.withOpacity(0.5),
        strokeWidth: 2,
      ),
    );
  }


  // --- DIRECTIONS API LOGIC ---
  Future<void> _fetchDynamicDetour() async {
    if (_polylines.isNotEmpty) return; // Prevent spamming API


    setState(() => _isLoadingRoute = true);


    // Call Google Directions API bypassing Chandni Chowk
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${kothrudDepot.latitude},${kothrudDepot.longitude}&'
        'destination=${bavdhanExit.latitude},${bavdhanExit.longitude}&'
        'mode=driving&'
        'key=$_googleApiKey';


    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'OK') {
          // Extract encoded polyline
          String encodedPolyline = jsonResponse['routes'][0]['overview_polyline']['points'];
         
          // Decode polyline points
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);
         
          List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();


          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('dynamic_detour'),
                color: Colors.greenAccent,
                width: 6,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                points: polylineCoordinates,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }


  void _updateSimulation(double time) {
    setState(() {
      _currentTime = time;


      // Congestion hits between 5:30 PM (17.5) and 8:00 PM (20.0)
      if (time >= 17.5 && time <= 20.0) {
        _isCongested = true;
       
        _markers = {
          Marker(
            markerId: const MarkerId('jam_1'),
            position: chandniChowk,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Critical Congestion'),
          ),
        };


        // Trigger the actual API call
        _fetchDynamicDetour();
       
      } else {
        _isCongested = false;
        _markers.clear();
        _polylines.clear();
      }
    });
  }


  String _formatTime(double time) {
    int hours = time.toInt();
    int minutes = ((time - hours) * 60).toInt();
    String period = hours >= 12 ? "PM" : "AM";
    if (hours > 12) hours -= 12;
    if (hours == 0) hours = 12;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: kothrudCenter, zoom: 13.5),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),


          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isCongested ? Colors.redAccent.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                      width: _isCongested ? 2 : 1,
                    ),
                    boxShadow: [
                      if (_isCongested)
                        BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Kothrud Pre-Shock Engine",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          _isLoadingRoute
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isCongested
                                      ? const Icon(Icons.warning_rounded, color: Colors.redAccent, key: ValueKey('warn'))
                                      : const Icon(Icons.check_circle_outline, color: Colors.greenAccent, key: ValueKey('ok')),
                                )
                        ],
                      ),
                      const SizedBox(height: 20),
                     
                      Text(
                        _formatTime(_currentTime),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _isCongested ? Colors.redAccent : Colors.cyanAccent,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: _currentTime,
                          min: 0.0,
                          max: 23.5,
                          divisions: 47,
                          onChanged: _updateSimulation,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
