import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class CrowdMapScreen extends StatefulWidget {
  const CrowdMapScreen({super.key});

  @override
  State<CrowdMapScreen> createState() => _CrowdMapScreenState();
}

class _CrowdMapScreenState extends State<CrowdMapScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref("crowded_area");
  LatLng? _currentCenter;
  int _blockDuration = 1;
  String _density = "Medium"; // Default selection

  // Mapping density to radius and color for the map
  double _getRadius(String density) {
    switch (density) {
      case "Low": return 200.0;
      case "High": return 800.0;
      default: return 500.0; // Medium
    }
  }

  Future<void> _addCrowdedArea(LatLng position, int hours, String density) async {
    final int expiry = DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;

    await _db.push().set({
      "lat": position.latitude,
      "lng": position.longitude,
      "radius": _getRadius(density),
      "density": density,
      "expiryTime": expiry,
      "timestamp": ServerValue.timestamp,
    });
  }

  void _showReportForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Report Crowd Intensity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Density Selection (Segmented-like buttons)
                  const Text("Estimated Crowd Size:"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["Low", "Medium", "High"].map((d) {
                      bool isSelected = _density == d;
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (val) => setModalState(() => _density = d),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),
                  Text("Expected Clearance: $_blockDuration Hour(s)"),
                  Slider(
                    value: _blockDuration.toDouble(),
                    min: 1, max: 12, divisions: 11,
                    activeColor: Colors.red,
                    onChanged: (val) => setModalState(() => _blockDuration = val.toInt()),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: StadiumBorder()),
                      onPressed: () {
                        if (_currentCenter != null) {
                          _addCrowdedArea(_currentCenter!, _blockDuration, _density);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Alert Published!"), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text("MARK AREA AS CROWDED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    return Scaffold(
      appBar: AppBar(title: const Text("Crowd Watch"), backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
      body: Stack(
        children: [
          StreamBuilder(
            stream: _db.orderByChild("expiryTime").startAt(now).onValue,
            builder: (context, snapshot) {
              Set<Circle> crowdCircles = {};

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
                data.forEach((key, value) {
                  String d = value['density'] ?? "Medium";
                  crowdCircles.add(Circle(
                    circleId: CircleId(key),
                    center: LatLng(value['lat'], value['lng']),
                    radius: value['radius'].toDouble(),
                    // Color gets darker based on density
                    fillColor: d == "High" ? Colors.red[900]!.withOpacity(0.6) : 
                              d == "Medium" ? Colors.red[600]!.withOpacity(0.4) : 
                              Colors.red[300]!.withOpacity(0.3),
                    strokeWidth: 0,
                  ));
                });
              }

              return GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(19.0760, 72.8777), zoom: 13),
                circles: crowdCircles,
                onCameraMove: (position) => _currentCenter = position.target,
                myLocationEnabled: true,
              );
            },
          ),
          const Center(child: Icon(Icons.location_searching, color: Colors.red, size: 40)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportForm,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text("Report Crowd", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}