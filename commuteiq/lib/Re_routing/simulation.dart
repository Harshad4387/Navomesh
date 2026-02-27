import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(home: RouteSimulationPage()));
}

class RouteSimulationPage extends StatefulWidget {
  const RouteSimulationPage({super.key});

  @override
  State<RouteSimulationPage> createState() => _RouteSimulationPageState();
}

class _RouteSimulationPageState extends State<RouteSimulationPage> {
  // 📊 Simulated Backend State: Tracking current "load" on each road
  // In a real app, these values would come from Firestore
  Map<String, int> roadLoad = {
    "Sus Road": 85,    // Current users assigned
    "Baner Road": 92,
    "Pashan Road": 78,
  };

  final int maxCapacityPerRoad = 100; // Threshold before a road is "Full"
  
  String? assignedRoute;
  int? estimatedTime;
  bool isCalculating = false;

  void simulateAllocation() async {
    setState(() {
      isCalculating = true;
      assignedRoute = null;
    });

    // Simulate network delay for "Deep Optimization"
    await Future.delayed(const Duration(seconds: 2));

    // 🧠 COLLECTIVE ALLOCATION LOGIC:
    // Find the road with the lowest current load (Nash Equilibrium approach)
    String bestRoad = roadLoad.keys.first;
    int minLoad = roadLoad[bestRoad]!;

    roadLoad.forEach((road, load) {
      if (load < minLoad) {
        minLoad = load;
        bestRoad = road;
      }
    });

    setState(() {
      assignedRoute = bestRoad;
      // Base time + a small penalty for current load
      estimatedTime = 40 + (roadLoad[bestRoad]! ~/ 5); 
      
      // Update the "Backend" - simulate assigning this user
      roadLoad[bestRoad] = roadLoad[bestRoad]! + 1;
      isCalculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pre-Trip Allocation Simulator")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🏙️ Pune Corridor Load (Backend View)", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            
            // Visualizing the Road Loads
            ...roadLoad.entries.map((entry) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text("${entry.value} / $maxCapacityPerRoad users"),
                  ],
                ),
                LinearProgressIndicator(
                  value: entry.value / maxCapacityPerRoad,
                  color: entry.value > 90 ? Colors.red : Colors.green,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 10),
              ],
            )),

            const Divider(height: 40),

            // User Interface
            Center(
              child: Column(
                children: [
                  const Text("📍 From: Baner  ➡️  To: Hinjewadi", 
                    style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  
                  if (isCalculating)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Optimizing route for collective flow..."),
                      ],
                    )
                  else if (assignedRoute != null)
                    _buildRouteCard()
                  else
                    ElevatedButton.icon(
                      onPressed: simulateAllocation,
                      icon: const Icon(Icons.search),
                      label: const Text("FIND BEST ROUTE"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    return Card(
      color: Colors.green[50],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green),
                const SizedBox(width: 10),
                Text("Fastest Route: $assignedRoute", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
            Text("⏱️ Estimated Time: $estimatedTime mins", style: const TextStyle(fontSize: 16)),
            const Text("🚦 Traffic: Distributed & Moderate", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                setState(() => assignedRoute = null); // Reset for next simulation
              },
              child: const Text("START NAVIGATION"),
            ),
            const SizedBox(height: 5),
            const Text("⚡ Smart Flow balancing active for this trip", 
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}