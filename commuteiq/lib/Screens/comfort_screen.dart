import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ComfortTravelScreen extends StatefulWidget {
  final String sourceName;
  final String destName;
  final double sourceLat;
  final double sourceLng;
  final double destLat;
  final double destLng;

  const ComfortTravelScreen({
    super.key,
    required this.sourceName,
    required this.destName,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<ComfortTravelScreen> createState() => _ComfortTravelScreenState();
}

class _ComfortTravelScreenState extends State<ComfortTravelScreen> {
  final List<Map<String, dynamic>> _mockRidersDatabase = [
    {'name': 'Rahul Sharma', 'company': 'Uber Premium', 'type': 'cab', 'lat': 18.5204, 'long': 73.8567, 'price': '₹150'},
    {'name': 'Amit Patil', 'company': 'Ola Prime', 'type': 'cab', 'lat': 18.5250, 'long': 73.8540, 'price': '₹140'},
    {'name': 'Suresh Kumar', 'company': 'Comfort Auto', 'type': 'rickshaw', 'lat': 18.5180, 'long': 73.8590, 'price': '₹80'},
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // --- LOGIC RETAINED ---
  void _showAnalysisDialog() {
    double distanceKm = _calculateDistance(widget.sourceLat, widget.sourceLng, widget.destLat, widget.destLng);
    int weatherSeverity = 0;
    int trafficCongestion = 1;
    var recommendation = getRecommendation(distanceKm, weatherSeverity, trafficCongestion);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Conditions Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [_infoChip(Icons.wb_sunny, "Clear Weather"), const SizedBox(width: 8), _infoChip(Icons.traffic, "Heavy Traffic")]),
              const Divider(height: 30),
              const Text("Suggested for Comfort & Speed:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...recommendation.map((vehicle) => ListTile(
                leading: Icon(_getVehicleIcon(vehicle['type'])),
                title: Text(vehicle['type'].toString().toUpperCase()),
                trailing: Text("₹${vehicle['fare']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Optimal score for current traffic"),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  IconData _getVehicleIcon(String type) {
    if (type == 'bike') return Icons.pedal_bike;
    if (type == 'auto') return Icons.electric_rickshaw;
    return Icons.local_taxi;
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Icon(icon, size: 16), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 12))]),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  List<Map<String, dynamic>> getRecommendation(double distanceKm, int weatherSev, int trafficCong) {
    Map<String, int> scores = {'bike': 0, 'auto': 0, 'cab': 0};
    if (weatherSev == 1) { scores['cab'] = scores['cab']! + 3; scores['auto'] = scores['auto']! + 1; scores['bike'] = scores['bike']! - 2; }
    else { scores['bike'] = scores['bike']! + 2; scores['auto'] = scores['auto']! + 1; }
    if (trafficCong == 1) { scores['bike'] = scores['bike']! + 2; scores['auto'] = scores['auto']! + 1; }
    else { scores['cab'] = scores['cab']! + 1; }
    if (distanceKm < 3) scores['bike'] = scores['bike']! + 2;
    else if (distanceKm < 7) scores['auto'] = scores['auto']! + 2;
    else scores['cab'] = scores['cab']! + 2;
    var sortedEntries = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    Map<String, double> fareMap = {
      'bike': double.parse((distanceKm * 6).toStringAsFixed(2)),
      'auto': double.parse((distanceKm * 15).toStringAsFixed(2)),
      'cab': double.parse((distanceKm * 18).toStringAsFixed(2)),
    };
    return sortedEntries.map((e) => {'type': e.key, 'fare': fareMap[e.key]}).toList();
  }

  // --- UPDATED UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. MAP SECTION
                Positioned(
                  top: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.45,
                  child: Container(
                    color: Colors.indigo[50],
                    child: const Center(child: Icon(Icons.map, size: 50, color: Colors.indigo)),
                  ),
                ),

                // 2. FLOATING HEADER
                Positioned(
                  top: 50, left: 20, right: 20,
                  child: _buildFloatingHeader(),
                ),

                // 3. DRAGGABLE PLAN SHEET
                DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.55,
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
                          Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 15), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                          
                          // ✅ FEATURE TITLE MENTIONED AT TOP
                          const Center(
                            child: Text(
                              "COMFORT TRAVEL PLANNER",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.indigo,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildTripHighlights(),
                          
                          const SizedBox(height: 20),
                          _buildAnalyzerButton(),
                          
                          const Divider(height: 40),
                          
                          const Text("COMFORT MULTIMODAL PLAN", 
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2, color: Colors.blueGrey)),
                          const SizedBox(height: 20),
                          
                          _buildJourneyTimeline(),
                          
                          const SizedBox(height: 30),
                          const Text("AVAILABLE SINGLE RIDE CONNECTORS", 
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.black54, fontSize: 11)),
                          const SizedBox(height: 15),
                          _buildSingleRiderSection(),
                          
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

  Widget _buildFloatingHeader() {
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
          Expanded(child: Text(widget.sourceName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.destName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
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
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: Text("MOST COMFORTABLE", style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            const Text("22 min", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            Text("Arrives at 02:45 PM", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.local_taxi, color: Colors.indigo, size: 30)),
            const SizedBox(height: 8),
            Text("₹145 • Premium Class", style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildAnalyzerButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAnalysisDialog,
        icon: const Icon(Icons.analytics_outlined, size: 18),
        label: const Text("ANALYZER ENGINE", style: TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.indigo,
          side: BorderSide(color: Colors.indigo.shade100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildJourneyTimeline() {
    return Column(
      children: [
        _timelineStep(Icons.directions_walk, "Priority Pickup Point", "1 min walk to Gate 1", "2 min", isFirst: true, dotColor: Colors.orange),
        _timelineStep(Icons.subway, "Metro Line 2 (Aqua)", "Platform 1 • Towards East", "12 min", dotColor: Colors.blueAccent, showAction: true),
        _timelineStep(Icons.local_taxi, "Private Executive Cab", "Awaiting at Exit B • MP-04-XY-1234", "8 min", isLast: true, dotColor: Colors.black),
      ],
    );
  }

  Widget _timelineStep(IconData icon, String title, String subtitle, String time, {Color dotColor = Colors.grey, bool isFirst = false, bool isLast = false, bool showAction = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 2, height: 10, color: isFirst ? Colors.transparent : Colors.grey[200]),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: dotColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: dotColor, size: 18)),
              Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey[200])),
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(time, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  if (showAction) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {},
                      child: Text("VIEW METRO QR", style: TextStyle(color: Colors.blue[800], fontSize: 10, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
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

  Widget _buildSingleRiderSection() {
    return Column(children: _mockRidersDatabase.map((rider) => _buildRiderCard(rider)).toList());
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    bool isCab = rider['type'] == 'cab';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.indigo[50], radius: 24, child: Icon(isCab ? Icons.local_taxi : Icons.electric_rickshaw, color: Colors.indigo)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rider['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(rider['company'], style: const TextStyle(fontSize: 11, color: Colors.grey))])),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rider['price'], style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 16)),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {}, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(70, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: const Text("Book", style: TextStyle(fontSize: 11))
              )
            ],
          )
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
        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2),
        child: const Text("CONFIRM COMFORT TICKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
      ),
    );
  }
}