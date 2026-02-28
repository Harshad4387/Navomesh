import 'dart:convert';
import 'dart:math';
import 'package:commuteiq/Grouping_feature/nearby_page.dart';
import 'package:commuteiq/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  void _navigateToGroupRide() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyUsersPage(
            destinationId: widget.destName.split(',')[0].trim(), 
            destinationName: widget.destName,
            destLat: widget.destLat,
            destLng: widget.destLng,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Catch: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // 1. TOP MAP SECTION (Placeholder for Google Map)
              Positioned(
                top: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.4,
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.map, size: 50, color: Colors.grey)),
                ),
              ),

              // 2. SEARCH BAR OVERLAY
              Positioned(
                top: 50, left: 20, right: 20,
                child: _buildFloatingSearchBar(),
              ),

              // 3. DRAGGABLE BOTTOM SHEET
              DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 20), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                        
                        _buildTripHighlights(),
                        
                        const Divider(height: 40),
                        
                        const Text("MULTIMODAL PLAN", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2, color: Colors.blueGrey)),
                        const SizedBox(height: 20),
                        
                        _buildJourneyTimeline(),
                        
                        const SizedBox(height: 20),
                        
                        GestureDetector(
                          onTap: _navigateToGroupRide,
                          child: _buildGroupRideSection(),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        _buildGenerateTokenButton(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          const CircleAvatar(radius: 4, backgroundColor: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.sourceName, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.destName, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildTripHighlights() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text("FASTEST", style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            const Text("28 min", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            Text("Arrives at 10:45 AM", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.directions_bus_filled, color: Colors.green, size: 30)),
            const SizedBox(height: 8),
            Text("₹45 • -1.2kg CO2", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildJourneyTimeline() {
    return Column(
      children: [
        _timelineStep(Icons.directions_walk, "Walk to Hub", "400m • Main St Entrance", "5 min", isFirst: true),
        _timelineStep(Icons.subway, "Metro Line 1", "Platform 2 • On Time", "15 min", color: Colors.blueAccent, showAction: true),
        _timelineStep(Icons.directions_car, "Auto to Destination", "Booked • KA-05-MJ-1234", "8 min", isLast: true),
      ],
    );
  }

  Widget _timelineStep(IconData icon, String title, String subtitle, String time, {Color color = Colors.grey, bool isFirst = false, bool isLast = false, bool showAction = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 2, height: 10, color: isFirst ? Colors.transparent : Colors.grey[300]),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(time, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  if (showAction) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showMetroQR("AQUA", "Central"),
                      child: Text("VIEW TICKET", style: TextStyle(color: Colors.blue[800], fontSize: 11, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                    )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupRideSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.blueGrey),
          const SizedBox(width: 12),
          const Expanded(child: Text("Group Ride", style: TextStyle(fontWeight: FontWeight.bold))),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }

  Widget _buildGenerateTokenButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text("Generate QR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}