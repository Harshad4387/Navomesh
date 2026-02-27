import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Renamed class to MapWithMetro
class MapWithMetro extends StatefulWidget {
  const MapWithMetro({super.key});

  @override
  State<MapWithMetro> createState() => _MapWithMetroState();
}

class _MapWithMetroState extends State<MapWithMetro> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  /// Combined initialization for User Position and Metro Station Markers
  Future<void> _initMapData() async {
    await _determinePosition();
    await _fetchMetroStations();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 1. Handle Permissions and get Initial Position
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    if (mounted) {
      _currentPosition = position;
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndex: 2, 
        ),
      );
    }
  }

  /// 2. Fetch Metro Locations from Firestore based on MetroLocations collection
  Future<void> _fetchMetroStations() async {
    try {
      // Mapping to the MetroLocations collection from your database
      QuerySnapshot snapshot = await _db.collection('MetroLocations').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Extracting fields as per your schema
        final double lat = data['latitude'];
        final double lng = data['longitude'];
        final String name = data['name'];
        final String line = data['line'] ?? "Metro";

        _markers.add(
          Marker(
            markerId: MarkerId(doc.id), 
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: name,
              snippet: '$line Line Station',
            ),
            // ✅ Azure color icon for metro stations
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching metro locations: $e");
    }
  }

  void _updateLocationUI(Position position) {
    setState(() {
      _currentPosition = position;
      _markers.removeWhere((m) => m.markerId.value == 'current_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndex: 2,
        ),
      );
    });
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 14, 
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true, 
                  myLocationButtonEnabled: false,
                  markers: _markers, 
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                
                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: FloatingActionButton.small(
                    heroTag: "btn_back",
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Position pos = await Geolocator.getCurrentPosition();
          _updateLocationUI(pos);
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }
}