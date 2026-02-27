import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  bool _isAnalyzing = false;
  String _congestionStatus = "Tap to Analyze Traffic";

  // Hardcoded Signals Data
  final List<Map<String, dynamic>> _signals = [
    {"name": "University Circle Signal", "time": "45s", "status": "Heavy"},
    {"name": "Shivaji Nagar Square", "time": "20s", "status": "Moderate"},
    {"name": "Swargate Junction", "time": "10s", "status": "Clear"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeMapFeatures();
  }

  void _initializeMapFeatures() {
    // 1. Add Source and Destination Markers
    _markers.add(Marker(
      markerId: const MarkerId('source'),
      position: LatLng(widget.sourceLat, widget.sourceLng),
      infoWindow: InfoWindow(title: widget.sourceName),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    _markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: LatLng(widget.destLat, widget.destLng),
      infoWindow: InfoWindow(title: widget.destName),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    // 2. Create a simple direct Polyline
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [
        LatLng(widget.sourceLat, widget.sourceLng),
        LatLng(widget.destLat, widget.destLng),
      ],
      color: Colors.blueAccent,
      width: 5,
    ));
  }

  void _analyzeCongestion() async {
    setState(() {
      _isAnalyzing = true;
      _congestionStatus = "Analyzing Real-time Traffic...";
    });

    // Simulate Processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      _congestionStatus = "Congestion Detected: 12 min delay on Satara Road";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Private Vehicle Route"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. MAP WIDGET (Top 50% of screen)
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.sourceLat, widget.sourceLng),
                zoom: 13,
              ),
              onMapCreated: (controller) => _controller.complete(controller),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          // 2. BOTTOM INFO PANEL
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
                      const Text("Live Signals Tracker", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: _analyzeCongestion,
                        icon: _isAnalyzing 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.analytics, size: 18),
                        label: const Text("Analyze Traffic"),
                      )
                    ],
                  ),
                  Text(_congestionStatus, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 10),
                  
                  // Signals List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _signals.length,
                      itemBuilder: (context, index) {
                        final signal = _signals[index];
                        return _buildSignalItem(signal);
                      },
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
          Icon(Icons.traffic, color: statusColor, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text("Est. Wait: ${signal['time']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
}