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

  // --- ANALYSIS LOGIC ---
  void _showAnalysisDialog() {
    // 1. Calculate real distance based on coordinates
    double distanceKm = _calculateDistance(widget.sourceLat, widget.sourceLng, widget.destLat, widget.destLng);
    
    // 2. Mock external conditions (These could be fetched from an API in the future)
    int weatherSeverity = 0; // 0: Clear, 1: Rain/Storm
    int trafficCongestion = 1; // 0: Light, 1: Heavy

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
              Row(
                children: [
                  _infoChip(Icons.wb_sunny, "Clear Weather"),
                  const SizedBox(width: 8),
                  _infoChip(Icons.traffic, "Heavy Traffic"),
                ],
              ),
              const Divider(height: 30),
              const Text("Suggested for Comfort & Speed:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...recommendation.map((vehicle) => ListTile(
                leading: Icon(_getVehicleIcon(vehicle['type'])),
                title: Text(vehicle['type'].toString().toUpperCase()),
                trailing: Text("₹${vehicle['fare']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Optimal score for current traffic"),
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

  // --- DISTANCE & RECOMMENDATION ENGINE ---
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  List<Map<String, dynamic>> getRecommendation(double distanceKm, int weatherSev, int trafficCong) {
    Map<String, int> scores = {'bike': 0, 'auto': 0, 'cab': 0};
    if (weatherSev == 1) {
      scores['cab'] = scores['cab']! + 3;
      scores['auto'] = scores['auto']! + 1;
      scores['bike'] = scores['bike']! - 2;
    } else {
      scores['bike'] = scores['bike']! + 2;
      scores['auto'] = scores['auto']! + 1;
    }
    if (trafficCong == 1) {
      scores['bike'] = scores['bike']! + 2;
      scores['auto'] = scores['auto']! + 1;
    } else {
      scores['cab'] = scores['cab']! + 1;
    }
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

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comfort Journey Plan"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteSummary(),
                  const SizedBox(height: 15),
                  
                  // 🔥 NEW ANALYZER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showAnalysisDialog,
                      icon: const Icon(Icons.analytics_outlined, color: Colors.indigo),
                      label: const Text("ANALYZE WEATHER & TRAFFIC", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.indigo.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  const Text("COMFORT MULTIMODAL PLAN", 
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  _buildJourneyTimeline(),
                  const SizedBox(height: 25),
                  const Text("AVAILABLE SINGLE RIDE CONNECTORS", 
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildSingleRiderSection(),
                  const SizedBox(height: 30),
                  _buildGenerateTokenButton(),
                ],
              ),
            ),
    );
  }

  // (Keeping your previous helper methods: _buildSingleRiderSection, _buildJourneyTimeline, _buildRouteSummary, etc.)
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.indigo[50], child: Icon(isCab ? Icons.local_taxi : Icons.electric_rickshaw, color: Colors.indigo)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rider['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(rider['company'], style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          Text(rider['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(60, 35)), child: const Text("Book", style: TextStyle(fontSize: 12)))
        ],
      ),
    );
  }

  Widget _buildJourneyTimeline() {
    return Column(children: [
      _timelineStep(Icons.directions_walk, "Walk to Hub", "1 min to priority pickup", color: Colors.orange),
      _timelineStep(Icons.subway, "Metro Aqua Line", "Next: 02:15 PM", color: Colors.blue, isLive: true, trailing: const Icon(Icons.qr_code, color: Colors.blueAccent)),
      _timelineStep(Icons.local_taxi, "Private Connection", "Instant pickup", color: Colors.black, isLast: true),
    ]);
  }

  Widget _timelineStep(IconData icon, String title, String subtitle, {Color color = Colors.grey, bool isLive = false, Widget? trailing, bool isLast = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [Icon(icon, color: color), if (!isLast) Container(width: 2, height: 40, color: Colors.grey[300])]),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))), if (isLive) Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)), child: const Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))), if (trailing != null) trailing]),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
      ]))
    ]);
  }

  Widget _buildRouteSummary() {
    return Card(elevation: 0, color: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [const Icon(Icons.my_location, size: 18, color: Colors.green), const SizedBox(width: 12), Expanded(child: Text(widget.sourceName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))]),
        const SizedBox(height: 10),
        Row(children: [const Icon(Icons.location_on, size: 18, color: Colors.red), const SizedBox(width: 12), Expanded(child: Text(widget.destName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))]),
      ])),
    );
  }

  Widget _buildGenerateTokenButton() {
    return SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.qr_code_2), label: const Text("CONFIRM COMFORT JOURNEY"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))));
  }
}