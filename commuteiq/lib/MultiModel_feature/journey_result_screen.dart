import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class JourneySegment {
  final String mode;
  final String detail;
  final double cost;
  final int minutes;
  final String? arrivalTime; 
  final bool isLiveSynced;   
  final Color themeColor;
  final LatLng? location; // Store lat/lng for specific markers

  JourneySegment({
    required this.mode,
    required this.detail,
    required this.cost,
    required this.minutes,
    this.arrivalTime,
    this.isLiveSynced = false,
    this.themeColor = Colors.blueAccent,
    this.location,
  });
}

class JourneyResultScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;
  final List<Map<String, dynamic>> metroSchedules; 

  const JourneyResultScreen({
    super.key,
    required this.destination,
    required this.destinationName,
    required this.metroSchedules,
  });

  @override
  State<JourneyResultScreen> createState() => _JourneyResultScreenState();
}

class _JourneyResultScreenState extends State<JourneyResultScreen> {
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

  Future<void> _buildPerfectPlan() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      LatLng origin = LatLng(pos.latitude, pos.longitude);
      
      final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${widget.destination.latitude},${widget.destination.longitude}&mode=transit&key=$_apiKey");
      
      final response = await http.get(url);
      final googleData = json.decode(response.body);

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
            // Identify if it's Metro (Subway/Heavy Rail) vs Bus
            bool isMetro = transit["line"]["vehicle"]["type"] == "SUBWAY" || 
                           transit["line"]["vehicle"]["type"] == "METRO_RAIL" ||
                           transit["line"]["name"].toString().contains("Metro");

            String? liveArrivalTime;
            LatLng? stationLoc;

            // Logic to match Firestore schedules and handle station coordinates
            if (isMetro && widget.metroSchedules.isNotEmpty) {
              var match = widget.metroSchedules.firstWhere(
                (s) => s['station'].toString().toLowerCase().contains(transit["departure_stop"]["name"].toString().toLowerCase()),
                orElse: () => widget.metroSchedules.first,
              );
              liveArrivalTime = match['arrival'];
              
              // If your Firestore contains lat/lng, use them for the marker
              if (match.containsKey('lat') && match.containsKey('lng')) {
                stationLoc = LatLng(match['lat'], match['lng']);
              }
            }

            perfectSegments.add(JourneySegment(
              mode: isMetro ? "Metro" : "Bus",
              detail: "${transit["line"]["short_name"] ?? "Line"} to ${transit["arrival_stop"]["name"]}",
              cost: isMetro ? 20.0 : 15.0,
              minutes: duration,
              arrivalTime: liveArrivalTime ?? transit["departure_time"]["text"],
              isLiveSynced: !isMetro, // Simulate live sync for buses/shuttles
              themeColor: isMetro ? Colors.indigo : Colors.orange,
              location: stationLoc,
            ));

            if (stationLoc != null) {
              _markers.add(Marker(
                markerId: MarkerId(transit["departure_stop"]["name"]),
                position: stationLoc,
                infoWindow: InfoWindow(title: "Metro: ${transit["departure_stop"]["name"]}"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ));
            }
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
          _journeyStatus = "Fastest Route: Combined Metro & Bus";
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

  // Helper to decode Google Polyline points
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

  IconData _getIcon(String mode) {
    switch (mode) {
      case "Metro": return Icons.subway;
      case "Bus": return Icons.directions_bus;
      case "Walk": return Icons.directions_walk;
      default: return Icons.directions_transit;
    }
  }

  // QR Token Generation Logic
  void _showQR() {
    double totalCost = _segments.fold(0, (sum, s) => sum + s.cost);
    String data = "CORUSCANT_TOKEN|₹$totalCost|${widget.destinationName}";
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Multimodal Token", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Unified QR for Metro, Bus & Shuttle"),
            const SizedBox(height: 20),
            QrImageView(data: data, size: 200),
            const SizedBox(height: 10),
            const Text("Scan at any gated terminal", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey Plan'), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: widget.destination, zoom: 14),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_journeyStatus, 
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text("Estimated Trip", style: Theme.of(context).textTheme.titleLarge),
            Text("₹${totalCost.toInt()} Total Fare • $totalTime mins"),
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
              child: const Text("GENERATE UNIFIED TOKEN", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                    child: const Text("SYNCED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          if (s.arrivalTime != null)
            Text(s.arrivalTime!, style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}