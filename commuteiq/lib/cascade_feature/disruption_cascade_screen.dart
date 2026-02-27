import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class DisruptionCascadeScreen extends StatefulWidget {
  const DisruptionCascadeScreen({super.key});

  @override
  State<DisruptionCascadeScreen> createState() => _DisruptionCascadeScreenState();
}

class _DisruptionCascadeScreenState extends State<DisruptionCascadeScreen> {
  final String _apiKey = "AIzaSyA3vnLO1Ajwovs_I2IjAuDqEGMPeMpTBxc"; // Your API Key
  final _sessionToken = const Uuid().v4();
  
  // Selection State
  String _sourceName = "Search Source Stop";
  String _destName = "Search Destination Stop";
  bool isSimulationRunning = false;

  // Search Logic
  Future<List<dynamic>> _getAutocomplete(String input) async {
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=transit_station&key=$_apiKey&sessiontoken=$_sessionToken&location=19.0760,72.8777&radius=50000"; // Biased to Mumbai
    var response = await http.get(Uri.parse(url));
    return json.decode(response.body)['predictions'];
  }

  void _showSearchSheet(bool isSource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter Bus Stop Name...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => setState(() {}), // Triggers future builder
                onSubmitted: (val) async {
                  var results = await _getAutocomplete(val);
                  // For simulation, we take the first result
                  if (results.isNotEmpty) {
                    setState(() {
                      if (isSource) {
                        _sourceName = results[0]['description'];
                      } else {
                        _destName = results[0]['description'];
                      }
                    });
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: const Center(child: Text("Type to search real-time transit nodes")),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Cascade Predictor"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSelectionCard(),
            const SizedBox(height: 24),
            if (isSimulationRunning) _buildSimulationResult() else _buildEmptyState(),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          _searchTile(Icons.my_location, _sourceName, () => _showSearchSheet(true)),
          const Divider(height: 30),
          _searchTile(Icons.location_on, _destName, () => _showSearchSheet(false)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => setState(() => isSimulationRunning = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Check Disruption Cascade", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 15),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15))),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildSimulationResult() {
    // Feature Logic: Trigger simulation if Andheri and Bandra are found in the string
    bool hasDisruption = _sourceName.contains("Andheri") && _destName.contains("Bandra");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Live Route Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        _buildLegCard(hasDisruption),
        if (hasDisruption) _buildAlertBox(),
      ],
    );
  }

  Widget _buildLegCard(bool isDelayed) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(Icons.directions_bus, color: isDelayed ? Colors.red : Colors.green),
        title: const Text("Bus 221 (Expected)"),
        subtitle: Text(isDelayed ? "Stalled at Jogeshwari" : "On schedule"),
        trailing: Text(isDelayed ? "19m Late" : "On Time", style: TextStyle(color: isDelayed ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAlertBox() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text("Smart Pivot Recommendation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          _buildOption("Option A: Bus 214", "8:41 AM • Arrive On-Time", Colors.green, Icons.bolt),
          const Divider(),
          _buildOption("Option B: Stay on 221", "8:55 AM • 19m Late", Colors.grey, Icons.timer),
        ],
      ),
    );
  }

  Widget _buildOption(String title, String sub, Color color, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.route_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Enter stops to analyze disruptions along the route", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}