import 'package:commuteiq/Screens/economic_screen.dart';
import 'package:flutter/material.dart';

class TravelOptionsScreen extends StatelessWidget {
  // Data passed from Home Screen
  final String sourceName;
  final String destName;
  final double sourceLat;
  final double sourceLng;
  final double destLat;
  final double destLng;

  const TravelOptionsScreen({
    super.key,
    required this.sourceName,
    required this.destName,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Travel Mode"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // TOP HALF: Mode Selection (Economic, Comfort, Private)
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLocationHeader(),
                  const SizedBox(height: 25),
                  _modeButton(context, "ECONOMIC", Icons.directions_bus, Colors.green),
                  _modeButton(context, "COMFORT", Icons.train, Colors.orange),
                  _modeButton(context, " PRIVATE", Icons.directions_car, Colors.blueAccent),
                ],
              ),
            ),
          ),

          // BOTTOM HALF: Hardcoded Recommendations
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "Smart Recommendations",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  _recommendationTile(
                    "Fastest Route", 
                    "Metro + Walking (18 mins)", 
                    Icons.bolt, 
                    Colors.amber
                  ),
                  _recommendationTile(
                    "Eco-Friendly", 
                    "PMPML Bus Line 12 (₹15)", 
                    Icons.eco, 
                    Colors.green
                  ),
                  _recommendationTile(
                    "Group Choice", 
                    "Shared Shuttle (Nash Optimized)", 
                    Icons.groups, 
                    Colors.indigo
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.multiple_stop, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$sourceName ➔ $destName",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Inside TravelOptionsScreen class...

  Widget _modeButton(BuildContext context, String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: () {
            if (label == "ECONOMIC") {
              // Passing all initial data to the Economic Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EconomicTravelScreen(
                    sourceName: sourceName,
                    destName: destName,
                    sourceLat: sourceLat,
                    sourceLng: sourceLng,
                    destLat: destLat,
                    destLng: destLng,
                  ),
                ),
              );
            } else {
              _handleSelection(context, label);
            }
          },
          icon: Icon(icon, color: Colors.white),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _recommendationTile(String title, String sub, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  void _handleSelection(BuildContext context, String mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Processing $mode request for $destName...")),
    );
  }
}