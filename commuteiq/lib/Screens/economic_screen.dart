import 'dart:convert';
import 'dart:math';
import 'package:commuteiq/Grouping_feature/nearby_page.dart';
import 'package:commuteiq/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
// import 'group_ride_screen.dart'; // ✅ Import your new screen here

class EconomicTravelScreen extends StatefulWidget {
  final String sourceName;
  final String destName;
  final double sourceLat;
  final double sourceLng;
  final double destLat;
  final double destLng;

  const EconomicTravelScreen({
    super.key,
    required this.sourceName,
    required this.destName,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<EconomicTravelScreen> createState() => _EconomicTravelScreenState();
}

class _EconomicTravelScreenState extends State<EconomicTravelScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Mock Data for Group Rides (Nash Equilibrium logic)
  final Map<String, dynamic> _groupRideDetails = {
    "provider": "UrbanFlow Collective",
    "vehicle": "Smart Shuttle (EV)",
    "savings": "7 mins saved via Nash logic",
    "eta": "3 mins",
    "price": "₹25 (Fixed)"
  };

  bool _isLoading = true;
  List<Map<String, dynamic>> _matchedMetroSchedules = [];

  @override
  void initState() {
    super.initState();
    _loadMultimodalData();
  }

  Future<void> _loadMultimodalData() async {
    await _checkFirestoreForMetro(widget.destName);
    setState(() => _isLoading = false);
  }

  Future<void> _checkFirestoreForMetro(String stationName) async {
    try {
      QuerySnapshot schedules = await _db.collection('train_schedules').get();
      List<Map<String, dynamic>> foundStops = [];
      String cleanSearchName = stationName.split(',')[0].toLowerCase().trim();

      for (var doc in schedules.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('stops')) {
          List<dynamic> stops = data['stops'];
          for (var stop in stops) {
            String stationInDb = stop['station_name'].toString().toLowerCase();
            if (stationInDb.contains(cleanSearchName) || cleanSearchName.contains(stationInDb)) {
              foundStops.add({
                'train_id': doc.id,
                'arrival': stop['arrival_time'],
                'station': stop['station_name']
              });
            }
          }
        }
      }
      setState(() => _matchedMetroSchedules = foundStops);
    } catch (e) {
      debugPrint("Firestore Error: $e");
    }
  }

  void _showMetroQR(String trainId, String station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Metro Ticket: $station"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Aqua Line - Coruscant Transit"),
            const SizedBox(height: 20),
            QrImageView(
              data: "METRO_TOKEN_${trainId}_$station",
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 10),
            const Text("Scan at Metro Gate", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  // ✅ Navigation to Group Ride Details
// ✅ Navigation to Nearby Users / Group Ride Details
void _navigateToGroupRide() {
  debugPrint("Attempting to navigate to NearbyUsersPage...");
  debugPrint("Destination: ${widget.destName}");

  try {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          debugPrint("Building NearbyUsersPage...");
          return NearbyUsersPage(
            destinationId: widget.destName.split(',')[0].trim(), 
            destinationName: widget.destName,
            destLat: widget.destLat,
            destLng: widget.destLng,
          );
        },
      ),
    ).then((value) => debugPrint("Navigation Success"))
     .catchError((error) => debugPrint("Navigation Error: $error"));
  } catch (e) {
    debugPrint("Immediate Catch: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: const Text("Economic Journey Plan"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Replace 'ProfileScreen()' with your actual profile page class name
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRouteSummary(),
                const SizedBox(height: 25),
                const Text("MULTIMODAL PLAN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 15),
                _buildJourneyTimeline(),
                const SizedBox(height: 25),
                // ✅ Replaced Uber section with Group Ride
                GestureDetector(
                  onTap: _navigateToGroupRide,
                  child: _buildGroupRideSection(),
                ),
                const SizedBox(height: 30),
                _buildGenerateTokenButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildRouteSummary() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow(Icons.my_location, Colors.green, widget.sourceName),
            const SizedBox(height: 10),
            const Icon(Icons.more_vert, size: 16, color: Colors.grey),
            const SizedBox(height: 10),
            _summaryRow(Icons.location_on, Colors.red, widget.destName),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildJourneyTimeline() {
    return Column(
      children: [
        _timelineStep(Icons.directions_walk, "Walk to Hub", "2 mins to nearest pickup"),
        _timelineStep(
          Icons.subway, 
          _matchedMetroSchedules.isNotEmpty ? "Metro ${_matchedMetroSchedules.first['train_id']}" : "Aqua Line Metro", 
          "Next: ${_matchedMetroSchedules.isNotEmpty ? _matchedMetroSchedules.first['arrival'] : '12:45 PM'}",
          color: Colors.blue,
          isLive: true,
          trailing: IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.blueAccent),
            onPressed: () => _showMetroQR(
              _matchedMetroSchedules.isNotEmpty ? _matchedMetroSchedules.first['train_id'] : "AQUA",
              _matchedMetroSchedules.isNotEmpty ? _matchedMetroSchedules.first['station'] : "Central Hub",
            ),
          ),
        ),
        // ✅ Changed Uber Connect to Group Ride in Timeline
        _timelineStep(
          Icons.groups, 
          "Group Ride (Shared)", 
          "Collective Optimization Active", 
          color: Colors.indigo,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _timelineStep(IconData icon, String title, String subtitle, {Color color = Colors.grey, bool isLive = false, Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color),
            Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (isLive) ...[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)), child: const Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                  if (trailing != null) trailing,
                ],
              ),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
            ],
          ),
        )
      ],
    );
  }

  // ✅ New Group Ride UI Section
  Widget _buildGroupRideSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Nash Optimized Group Ride", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text(_groupRideDetails['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.indigo),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.airport_shuttle, color: Colors.white)),
            title: Text(_groupRideDetails['provider']),
            subtitle: Text(_groupRideDetails['savings']),
            trailing: Text(_groupRideDetails['eta'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const Center(
            child: Text("Tap to view allocation and route details", style: TextStyle(fontSize: 10, color: Colors.indigo)),
          )
        ],
      ),
    );
  }

  Widget _buildGenerateTokenButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unified Token Generated!")));
        },
        icon: const Icon(Icons.qr_code_2),
        label: const Text("GENERATE MULTIMODAL TOKEN", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}