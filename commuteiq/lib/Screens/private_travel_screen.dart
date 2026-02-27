import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PrivateTravelScreen extends StatefulWidget {
  final String sourceName;
  final String destName;
  final double sourceLat;
  final double sourceLng;
  final double destLat;
  final double destLng;

  const PrivateTravelScreen({
    super.key,
    required this.sourceName,
    required this.destName,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<PrivateTravelScreen> createState() => _PrivateTravelScreenState();
}

class _PrivateTravelScreenState extends State<PrivateTravelScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  static const String _apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc";
  static const String _mlServerUrl = "https://b9m28n2k-8000.inc1.devtunnels.ms/vehicle-count";

  bool _isAnalyzing = false;
  String _congestionStatus = "Tap to Analyze Multiple Routes";
  

  final List<Map<String, dynamic>> _signals = [
    {
      "name": "University Circle Signal",
      "time": "45s",
      "status": "Clear",
      "lat": 18.5515,
      "lng": 73.8235
    },
    {
      "name": "Shivaji Nagar Square",
      "time": "20s",
      "status": "Clear",
      "lat": 18.5314,
      "lng": 73.8552
    },
    {
      "name": "Swargate Junction",
      "time": "10s",
      "status": "Clear",
      "lat": 18.5018,
      "lng": 73.8636
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _getMultipleDirections();
  }

  void _initializeMarkers() {
    _markers.add(Marker(
      markerId: const MarkerId('source'),
      position: LatLng(widget.sourceLat, widget.sourceLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    _markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: LatLng(widget.destLat, widget.destLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
  }

  Future<void> _getMultipleDirections() async {
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${widget.sourceLat},${widget.sourceLng}&destination=${widget.destLat},${widget.destLng}&alternatives=true&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List routes = data['routes'];
          setState(() {
            _polylines.clear();
            for (int i = 0; i < routes.length; i++) {
              final points = routes[i]['overview_polyline']['points'];
              _polylines.add(Polyline(
                polylineId: PolylineId('route_$i'),
                points: _decodePolyline(points),
                color: i == 0 ? Colors.blueAccent : Colors.red.withOpacity(0.7),
                width: i == 0 ? 6 : 4,
                zIndex: i == 0 ? 1 : 0,
              ));
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Directions Error: $e");
    }
  }

  Future<void> _analyzeCongestion() async {
    setState(() {
      _isAnalyzing = true;
      _congestionStatus = "Syncing with ML Vision nodes...";
      _circles.clear();
    });

    try {
      final response = await http.get(Uri.parse(_mlServerUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool hasAlert = data['alert'] ?? false;
        
        setState(() {
          _isAnalyzing = false;
          if (hasAlert) {
            _congestionStatus = "ML ALERT: Heavy Traffic at University Circle!";
            _signals[0]['status'] = "Heavy";

            _circles.add(Circle(
              circleId: const CircleId("heavy_zone_1"),
              center: LatLng(_signals[0]['lat'], _signals[0]['lng']),
              radius: 250,
              fillColor: Colors.red.withOpacity(0.4),
              strokeColor: Colors.red,
              strokeWidth: 2,
            ));
            _animateToPos(_signals[0]['lat'], _signals[0]['lng']);
          } else {
            _congestionStatus = "AI SCAN: Traffic normal. Alternative paths clear.";
            _signals[0]['status'] = "Clear";
          }
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _congestionStatus = "Sync Error: Dev Tunnel offline.";
      });
    }
  }

  Future<void> _animateToPos(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Multi-Route Intelligence"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(widget.sourceLat, widget.sourceLng), zoom: 13),
              onMapCreated: (controller) => _controller.complete(controller),
              markers: _markers,
              polylines: _polylines,
              circles: _circles,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Signal Comparison", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: _analyzeCongestion,
                        icon: _isAnalyzing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.psychology, size: 18),
                        label: const Text("Scan Routes"),
                      )
                    ],
                  ),
                  Text(_congestionStatus, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  const Divider(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _signals.length,
                      itemBuilder: (context, index) => _buildSignalItem(_signals[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalItem(Map<String, dynamic> signal) {
    Color statusColor = signal['status'] == 'Heavy' ? Colors.red : (signal['status'] == 'Moderate' ? Colors.orange : Colors.green);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.traffic, color: statusColor, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text("Delay: ${signal['time']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
            child: Text(signal['status'], style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}