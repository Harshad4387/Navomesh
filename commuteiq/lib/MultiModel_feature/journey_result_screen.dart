import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Model for the "Perfect Plan" segments
class JourneySegment {
  final String mode;
  final String detail;
  final double cost;
  final int minutes;
  final String? arrivalTime; // Simulating Firestore static data
  final bool isLiveSynced;   // Simulating the 'Shuttle Hold' logic
  final Color themeColor;

  JourneySegment({
    required this.mode,
    required this.detail,
    required this.cost,
    required this.minutes,
    this.arrivalTime,
    this.isLiveSynced = false,
    this.themeColor = Colors.blueAccent,
  });
}

class JourneyResultScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;

  const JourneyResultScreen({
    super.key,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<JourneyResultScreen> createState() => _JourneyResultScreenState();
}

class _JourneyResultScreenState extends State<JourneyResultScreen> {
  // Replace with your actual key
  static const String _apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc"; 

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<JourneySegment> _segments = [];
  bool _isLoading = true;
  String _journeyStatus = "Analyzing transit nodes...";

  @override
  void initState() {
    super.initState();
    _buildPerfectPlan();
  }

  /// ── The Perfect Plan Orchestrator ──────────────────────────────────────
  Future<void> _buildPerfectPlan() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      LatLng origin = LatLng(pos.latitude, pos.longitude);
      
      final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${widget.destination.latitude},${widget.destination.longitude}&mode=transit&key=$_apiKey");
      
      final response = await http.get(url);
      final googleData = json.decode(response.body);

      // MOCK FIRESTORE DATA (Priya's Scenario)
      // In production, fetch these from Firestore based on station names
      String mockMetroArrival = "10:05 AM"; 
      bool mockShuttleHold = true; 

      if (googleData["status"] == "OK") {
        final route = googleData["routes"][0];
        final leg = route["legs"][0];
        List<JourneySegment> perfectSegments = [];

        for (var step in leg["steps"]) {
          String mode = step["travel_mode"];
          String rawDetail = step["html_instructions"].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), "");
          int duration = step["duration"]["value"] ~/ 60;

          if (mode == "TRANSIT") {
            var transit = step["transit_details"];
            bool isMetro = transit["line"]["vehicle"]["type"] != "BUS";

            perfectSegments.add(JourneySegment(
              mode: isMetro ? "Metro" : "Shuttle",
              detail: isMetro ? "Yellow Line to ${transit["arrival_stop"]["name"]}" : "Shuttle S4 to Cyber City",
              cost: isMetro ? 32.0 : 15.0,
              minutes: duration,
              arrivalTime: isMetro ? mockMetroArrival : "Synced",
              isLiveSynced: !isMetro && mockShuttleHold,
              themeColor: isMetro ? Colors.blue : Colors.orange,
            ));
          } else {
            perfectSegments.add(JourneySegment(
              mode: "Walk",
              detail: rawDetail,
              cost: 0,
              minutes: duration,
              themeColor: Colors.grey,
            ));
          }
        }

        setState(() {
          _segments = perfectSegments;
          _journeyStatus = "₹293 cheaper than Uber • 21 mins saved";
          _isLoading = false;
          _markers.add(Marker(markerId: const MarkerId("origin"), position: origin, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
          _markers.add(Marker(markerId: const MarkerId("dest"), position: widget.destination));
          _polylines.add(Polyline(
            polylineId: const PolylineId("path"), 
            points: _decodePolyline(route["overview_polyline"]["points"]), 
            color: Colors.blueAccent, 
            width: 5
          ));
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  /// ── HELPER: Decode Polyline ───────────────────────────────────────────
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// ── HELPER: Icon Selector ─────────────────────────────────────────────
  IconData _getIcon(String mode) {
    switch (mode) {
      case "Metro": return Icons.train;
      case "Shuttle": return Icons.bus_alert;
      case "Walk": return Icons.directions_walk;
      default: return Icons.directions_transit;
    }
  }

  /// ── HELPER: Show Single Token QR ──────────────────────────────────────
  void _showQR() {
    double totalCost = _segments.fold(0, (sum, s) => sum + s.cost);
    String data = "PRIYA_FLOW_CITY_TOKEN|₹$totalCost|${widget.destinationName}";
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Single-Journey Token", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Valid for Metro & Shuttle S4"),
            const SizedBox(height: 20),
            QrImageView(data: data, size: 200),
            const SizedBox(height: 10),
            const Text("Scan at any FlowCity terminal", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfect Plan'), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: widget.destination, zoom: 13),
                markers: _markers,
                polylines: _polylines,
              ),
              _buildDraggableSheet(),
            ],
          ),
    );
  }

  Widget _buildDraggableSheet() {
    double totalCost = _segments.fold(0, (sum, s) => sum + s.cost);
    int totalTime = _segments.fold(0, (sum, s) => sum + s.minutes);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(blurRadius: 15, color: Colors.black12)],
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            // Savings Badge (The Priya Scenario Highlight)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_journeyStatus, 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text("Journey Details", style: Theme.of(context).textTheme.titleLarge),
            Text("₹${totalCost.toInt()} • $totalTime mins total"),
            const Divider(height: 30),
            ..._segments.map((s) => _buildLegItem(s)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text("BOOK ALL & GENERATE QR", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegItem(JourneySegment s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(_getIcon(s.mode), color: s.themeColor, size: 22),
              Container(width: 1, height: 35, color: Colors.grey[200]),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.mode, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(s.detail, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                if (s.isLiveSynced) 
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                    child: const Text("SHUTTLE HOLDING", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          if (s.arrivalTime != null)
            Text(s.arrivalTime!, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}