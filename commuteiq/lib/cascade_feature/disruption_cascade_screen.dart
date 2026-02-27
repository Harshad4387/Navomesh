import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// --- PUNE DATA MODELS ---
class TransitIncident {
  final String location;
  final String cause;
  final int delayMinutes;
  final String affectedBus;
  final String altBus;
  final String altNote;

  TransitIncident({
    required this.location,
    required this.cause,
    required this.delayMinutes,
    required this.affectedBus,
    required this.altBus,
    required this.altNote,
  });
}

class DisruptionCascadeScreen extends StatefulWidget {
  const DisruptionCascadeScreen({super.key});

  @override
  State<DisruptionCascadeScreen> createState() => _DisruptionCascadeScreenState();
}

class _DisruptionCascadeScreenState extends State<DisruptionCascadeScreen> {
  final String _apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc"; 
  final _sessionToken = const Uuid().v4();

  // Simulation State
  String _sourceName = "Search Source Stop";
  String _destName = "Search Destination Stop";
  bool isSimulationRunning = false;
  bool isAnalyzing = false;
  TransitIncident? detectedIncident;

  // Mock Database of "Live" Issues in Pune
  final List<TransitIncident> _activeIncidents = [
    TransitIncident(
      location: "Khadki Station",
      cause: "Broken Down Truck on BRT Lane",
      delayMinutes: 22,
      affectedBus: "42 (Pimpri to Pune Stn)",
      altBus: "Purple Line Metro",
      altNote: "Walk to PCMC Metro, Arrive 15m Early",
    ),
    TransitIncident(
      location: "University Circle",
      cause: "Signal Failure / Heavy Traffic",
      delayMinutes: 35,
      affectedBus: "100 (Hinjewadi to Corp)",
      altBus: "204 (Via Baner)",
      altNote: "Alternate route via Pashan, moving faster",
    ),
  ];

  // --- LOGIC ---

  Future<List<dynamic>> _getAutocomplete(String input) async {
    if (input.isEmpty) return [];
    // BIAS: 18.5204, 73.8567 (Pune)
    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=transit_station&key=$_apiKey&sessiontoken=$_sessionToken&location=18.5204,73.8567&radius=30000";
    var response = await http.get(Uri.parse(url));
    return json.decode(response.body)['predictions'];
  }

  void _runSimulation() async {
    setState(() {
      isSimulationRunning = true;
      isAnalyzing = true;
      detectedIncident = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    // Simulation Engine: Pune Scenario (Pimpri -> Shivajinagar)
    for (var incident in _activeIncidents) {
      if ((_sourceName.toLowerCase().contains("pimpri") || _sourceName.toLowerCase().contains("pcmc")) &&
          (_destName.toLowerCase().contains("shivajinagar") || _destName.toLowerCase().contains("pune"))) {
        if (incident.location == "Khadki Station") {
          detectedIncident = incident;
        }
      }
    }

    setState(() => isAnalyzing = false);
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Pune Cascade Predictor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[800], // Pune PMPML/Metro Vibe
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSelectionCard(),
            const SizedBox(height: 24),
            if (isSimulationRunning) _buildSimulationView() else _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _searchTile(Icons.my_location, _sourceName, Colors.orange, () => _showSearchSheet(true)),
          const Padding(
            padding: EdgeInsets.only(left: 40),
            child: Divider(height: 30),
          ),
          _searchTile(Icons.location_on, _destName, Colors.red, () => _showSearchSheet(false)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _runSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Analyze Pune Traffic Path", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationView() {
    if (isAnalyzing) {
      return Column(
        children: [
          const SizedBox(height: 40),
          CircularProgressIndicator(color: Colors.orange[800]),
          const SizedBox(height: 16),
          const Text("Scanning Khadki & University bottlenecks...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Live Route Forecast", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
              child: const Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 12),
        _buildLegCard(),
        if (detectedIncident != null) _buildAlertBox(),
      ],
    );
  }

  Widget _buildLegCard() {
    bool hasIssue = detectedIncident != null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: hasIssue ? Colors.red.withOpacity(0.2) : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasIssue ? Colors.red[50] : Colors.green[50],
          child: Icon(Icons.directions_bus, color: hasIssue ? Colors.red : Colors.green),
        ),
        title: Text(hasIssue ? "PMPML Route ${detectedIncident!.affectedBus.split(' ')[0]}" : "Transit Route"),
        subtitle: Text(hasIssue ? "Stalled near ${detectedIncident!.location}" : "No disruptions on route"),
        trailing: Text(hasIssue ? "+${detectedIncident!.delayMinutes}m" : "On Time", 
          style: TextStyle(color: hasIssue ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAlertBox() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
              SizedBox(width: 10),
              Text("Smart Pune Pivot", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildOption("Switch to ${detectedIncident!.altBus}", detectedIncident!.altNote, Colors.amber, Icons.bolt),
          const Divider(color: Colors.white24),
          _buildOption("Stay on PMPML Bus", "Arrive ${detectedIncident!.delayMinutes}m Late", Colors.white70, Icons.timer),
        ],
      ),
    );
  }

  Widget _buildOption(String title, String sub, Color color, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }

  Widget _searchTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          const Icon(Icons.unfold_more, color: Colors.grey),
        ],
      ),
    );
  }

  void _showSearchSheet(bool isSource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter Stop (Try 'Pimpri' or 'Shivajinagar')",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onSubmitted: (val) async {
                  var results = await _getAutocomplete(val);
                  if (results.isNotEmpty) {
                    setState(() {
                      if (isSource) { _sourceName = results[0]['description']; } 
                      else { _destName = results[0]['description']; }
                    });
                    Navigator.pop(context);
                  }
                },
              ),
              const Expanded(child: Center(child: Text("Select a Pune transit station", style: TextStyle(color: Colors.grey)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.directions_bus_filled_outlined, size: 100, color: Colors.orange[50]),
        const SizedBox(height: 16),
        const Text("Simulate Pune Journey", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: Text("Search 'Pimpri' as Source and 'Shivajinagar' as Destination to see the Khadki cascade in action.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}