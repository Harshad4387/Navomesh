import 'dart:async';
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------
class Commuter {
  final String name;
  final String timeString;
  final double individualCost;
  final String avatarUrl;
  final Alignment initialLocation;
  final bool isMatch;

  Commuter(this.name, this.timeString, this.individualCost, this.avatarUrl,
      this.initialLocation, this.isMatch);
}

// -----------------------------------------------------------------------------
// SCREEN 1: THE MAP RADAR SIMULATION
// -----------------------------------------------------------------------------
class ConvoyMapSimulationScreen extends StatefulWidget {
  const ConvoyMapSimulationScreen({super.key});

  @override
  State<ConvoyMapSimulationScreen> createState() =>
      _ConvoyMapSimulationScreenState();
}

class _ConvoyMapSimulationScreenState extends State<ConvoyMapSimulationScreen> {
  int daysAnalysed = 0;
  Timer? dayTimer;
  bool patternDetected = false;

  final List<Commuter> allCommuters = [
    Commuter("Rahul", "8:25 AM", 55, "https://i.pravatar.cc/150?u=1", const Alignment(-0.6, -0.4), true),
    Commuter("Priya", "8:30 AM", 60, "https://i.pravatar.cc/150?u=2", const Alignment(-0.3, -0.7), true),
    Commuter("Amit", "8:25 AM", 58, "https://i.pravatar.cc/150?u=3", const Alignment(-0.8, -0.2), true),
    Commuter("Sneha", "8:35 AM", 50, "https://i.pravatar.cc/150?u=4", const Alignment(-0.4, -0.1), true),
    Commuter("Vikram", "10:15 AM", 65, "https://i.pravatar.cc/150?u=5", const Alignment(-0.5, -0.5), false),
    Commuter("Neha", "10:30 AM", 60, "https://i.pravatar.cc/150?u=6", const Alignment(-0.7, -0.3), false),
    Commuter("Rohan", "7:10 AM", 120, "https://i.pravatar.cc/150?u=7", const Alignment(0.6, 0.5), false),
    Commuter("Kavita", "9:45 AM", 45, "https://i.pravatar.cc/150?u=8", const Alignment(0.8, -0.6), false),
    Commuter("Arjun", "6:30 AM", 40, "https://i.pravatar.cc/150?u=9", const Alignment(0.7, -0.1), false),
    Commuter("Pooja", "8:15 AM", 90, "https://i.pravatar.cc/150?u=10", const Alignment(0.1, 0.8), false),
  ];

  @override
  void initState() {
    super.initState();
    dayTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) setState(() => daysAnalysed++);
      if (daysAnalysed == 14) {
        timer.cancel();
        if (mounted) setState(() => patternDetected = true);
        final matchedConvoy = allCommuters.where((c) => c.isMatch).toList();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ConvoyAlertScreen(commuters: matchedConvoy)),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text("AI Area Scanning", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(child: Opacity(opacity: 0.05, child: FlutterLogo())),
          
          // Radar Text Overlay
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(patternDetected ? Icons.check_circle : Icons.radar, color: patternDetected ? Colors.green : Colors.blueAccent),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patternDetected ? "Micro-Convoy Found!" : "Analyzing Routines...", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Day $daysAnalysed of 14", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Central Society Hub
          Center(
            child: AnimatedScale(
              scale: patternDetected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_city, size: 60, color: Colors.blueAccent),
                  Text("Blue Ridge Society", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
                ],
              ),
            ),
          ),

          // Commuter Markers
          ...allCommuters.map((user) {
            final targetAlignment = (patternDetected && user.isMatch) ? const Alignment(0, 0) : user.initialLocation;
            final targetOpacity = (patternDetected && !user.isMatch) ? 0.0 : 1.0;

            return AnimatedAlign(
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              alignment: targetAlignment,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: targetOpacity,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: user.isMatch ? Colors.green : Colors.grey,
                  child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(user.avatarUrl)),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 2: DYNAMIC ALERT SCREEN
// -----------------------------------------------------------------------------
class ConvoyAlertScreen extends StatelessWidget {
  final List<Commuter> commuters;
  const ConvoyAlertScreen({super.key, required this.commuters});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Convoy Match Found"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo[800]!, Colors.indigo[400]!]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  Text("${commuters.length} neighbors are ready!", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Blue Ridge ➔ Hinjewadi Metro", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: commuters.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(commuters[i].avatarUrl)),
                  title: Text(commuters[i].name),
                  subtitle: Text("Departs at ${commuters[i].timeString}"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConvoyJoinSuccess())),
                child: const Text("JOIN CONVOY (₹25)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 3: SUCCESS SCREEN
// -----------------------------------------------------------------------------
class ConvoyJoinSuccess extends StatelessWidget {
  const ConvoyJoinSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Booking Confirmed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Meet at Gate 1 at 8:30 AM"),
            const SizedBox(height: 40),
            TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text("Back to Home"))
          ],
        ),
      ),
    );
  }
}