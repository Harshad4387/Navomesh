import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

class MultimodalSimulationScreen extends StatefulWidget {
  const MultimodalSimulationScreen({super.key});

  @override
  State<MultimodalSimulationScreen> createState() =>
      _MultimodalSimulationScreenState();
}

class _MultimodalSimulationScreenState
    extends State<MultimodalSimulationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isRouteGenerated = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Simulation journey
  final List<JourneySegment> _mockSegments = [
    JourneySegment(
      mode: 'Walking',
      detail: 'Walk to Metro Station',
      duration: Duration(minutes: 5),
      location: LatLng(18.5204, 73.8567),
    ),
    JourneySegment(
      mode: 'Metro',
      detail: 'Blue Line',
      cost: 25,
      duration: Duration(minutes: 15),
      location: LatLng(18.5314, 73.8446),
    ),
    JourneySegment(
      mode: 'Bus',
      detail: 'Feeder Bus 102',
      cost: 10,
      duration: Duration(minutes: 10),
      location: LatLng(18.5410, 73.8320),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Position position =
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _isLoading = false;
    });
  }

  void _generateSimulation() {
    _addMarkersAndRoute();
    setState(() => _isRouteGenerated = true);
  }

  void _addMarkersAndRoute() {
    _markers.clear();
    _polylines.clear();

    List<LatLng> routePoints = [];

    for (int i = 0; i < _mockSegments.length; i++) {
      final seg = _mockSegments[i];
      routePoints.add(seg.location);

      _markers.add(
        Marker(
          markerId: MarkerId(seg.mode + i.toString()),
          position: seg.location,
          infoWindow: InfoWindow(title: seg.mode, snippet: seg.detail),
        ),
      );
    }

    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: routePoints,
        width: 5,
      ),
    );
  }

  double get totalCost =>
      _mockSegments.fold(0, (sum, s) => sum + (s.cost ?? 0));

  int get totalMinutes =>
      _mockSegments.fold(0, (sum, s) => sum + s.duration.inMinutes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 13,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  onMapCreated: (c) => _mapController = c,
                ),

                if (!_isRouteGenerated)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: _buildSearchCard(),
                  ),

                if (_isRouteGenerated) _buildJourneyDrawer(),
              ],
            ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: "Enter Destination",
                icon: Icon(Icons.location_on, color: Colors.red),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _generateSimulation,
              child: const Text("Find Best Journey"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyDrawer() {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.15,
      maxChildSize: 0.65,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: [
              const Center(child: Icon(Icons.drag_handle)),
              ListTile(
                title: const Text(
                  "Single-Token Journey",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle:
                    Text("Total: ₹$totalCost • $totalMinutes mins"),
                trailing: const Icon(Icons.bolt, color: Colors.amber),
              ),
              const Divider(),
              ..._mockSegments.map((s) => ListTile(
                    leading: Icon(_getIcon(s.mode)),
                    title: Text("${s.mode}: ${s.detail}"),
                    subtitle: Text("${s.duration.inMinutes} mins"),
                    trailing:
                        s.cost != null ? Text("₹${s.cost}") : null,
                  )),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _showTokenDialog,
                  child: const Text("Generate Journey QR Token"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  IconData _getIcon(String mode) {
    switch (mode) {
      case 'Metro':
        return Icons.train;
      case 'Bus':
        return Icons.directions_bus;
      default:
        return Icons.directions_walk;
    }
  }

  void _showTokenDialog() {
    String tokenData =
        "JourneyID: IQ-9928-X\nCost: ₹$totalCost\nTime: $totalMinutes mins";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Your Journey Token"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Scan at any terminal"),
            const SizedBox(height: 20),
            QrImageView(
              data: tokenData,
              size: 200,
            ),
            const SizedBox(height: 10),
            Text(tokenData, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }
}

class JourneySegment {
  final String mode;
  final String detail;
  final double? cost;
  final Duration duration;
  final LatLng location;

  JourneySegment({
    required this.mode,
    required this.detail,
    this.cost,
    required this.duration,
    required this.location,
  });
}