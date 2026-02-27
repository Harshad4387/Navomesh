import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SimpleMapScreen extends StatefulWidget {
  const SimpleMapScreen({super.key});

  @override
  State<SimpleMapScreen> createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  
  // ✅ Variable to hold the marker
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// 1. Handle Permissions and get Initial Position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    if (mounted) {
      setState(() {
        _currentPosition = position;
        
        // ✅ Create the Marker
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'You are here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        
        _isLoading = false;
      });
    }
  }

  /// 2. Helper to move camera and update marker
  void _updateLocationUI(Position position) {
    setState(() {
      _currentPosition = position;
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      };
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
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  
                  // ✅ Shows the interactive blue dot
                  myLocationEnabled: true, 
                  myLocationButtonEnabled: false,
                  
                  // ✅ Shows your defined Marker pin
                  markers: _markers, 
                  
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                
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