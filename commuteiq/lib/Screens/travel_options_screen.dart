import 'package:commuteiq/Screens/economic_screen.dart';
import 'package:commuteiq/Screens/comfort_screen.dart'; 
import 'package:commuteiq/Screens/private_travel_screen.dart';
import 'package:commuteiq/Grouping_feature/nearby_page.dart';
import 'package:commuteiq/convoy/covoy.dart';
import 'package:commuteiq/paid_lift/paid_lift.dart'; 
// Ensure this path matches where you saved your simulation file

import 'package:flutter/material.dart';

class TravelOptionsScreen extends StatefulWidget {
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
  State<TravelOptionsScreen> createState() => _TravelOptionsScreenState();
}

class _TravelOptionsScreenState extends State<TravelOptionsScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      appBar: AppBar(
        title: const Text("Plan Your Journey", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildLocationHeader(),
                const SizedBox(height: 20),
                
                // ✅ USER GUIDANCE MESSAGE CARD
                _buildInstructionCard(),
                
                const SizedBox(height: 25),
                const Text(
                  "Available Solo Modes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 15),
                
                _modeButton(context, "ECONOMIC", "Budget buses & shared shuttles", Icons.directions_bus, Colors.green),
                _modeButton(context, "COMFORT", "Fast metro & premium travel", Icons.train, Colors.orange),
                _modeButton(context, "PRIVATE", "Personal cabs & door-to-door", Icons.directions_car, Colors.blueAccent),
                
                const Spacer(),
              ],
            ),
          ),
          
          // ✅ IMPROVED FLOATING BOTTOM BAR
          _buildFloatingBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_circle, color: Colors.indigo.shade400, size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Planning to save? Use the 'Group' button at the bottom to find neighbors heading your way.",
              style: TextStyle(fontSize: 13, color: Colors.indigo, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.ac_unit_sharp, "Group"),
            _buildNavItem(1, Icons.currency_rupee, "Lift"),
            _buildNavItem(2, Icons.groups, "Convoy"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTab = index);
        _handleBottomNav(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.indigo : Colors.grey.shade400, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED NAVIGATION LOGIC
  void _handleBottomNav(int index) {
    if (index == 0) {
      // 1. Navigate to REAL-TIME Group Matching
      String cleanDestId = widget.destName.split(',')[0].trim().toLowerCase();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyUsersPage(
            destinationId: cleanDestId, 
            destinationName: widget.destName,
            destLat: widget.destLat,
            destLng: widget.destLng,
          ),
        ),
      );
    } 
    else if (index == 2) {
      // 2. Navigate to CONVOY Simulation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConvoyMapSimulationScreen(),
        ),
      );
    } 
    else if (index == 1) {
       // 3. Paid Lift Placeholder
        Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaidLiftSimulationScreen(),
        ),
      );
    }
  }

  Widget _modeButton(BuildContext context, String label, String sub, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(label),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(String label) {
    Widget target;
    if (label == "ECONOMIC") {
      target = EconomicTravelScreen(sourceName: widget.sourceName, destName: widget.destName, sourceLat: widget.sourceLat, sourceLng: widget.sourceLng, destLat: widget.destLat, destLng: widget.destLng);
    } else if (label == "COMFORT") {
      target = ComfortTravelScreen(sourceName: widget.sourceName, destName: widget.destName, sourceLat: widget.sourceLat, sourceLng: widget.sourceLng, destLat: widget.destLat, destLng: widget.destLng);
    } else {
      target = PrivateTravelScreen(sourceName: widget.sourceName, destName: widget.destName, sourceLat: widget.sourceLat, sourceLng: widget.sourceLng, destLat: widget.destLat, destLng: widget.destLng);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${widget.sourceName} ➔ ${widget.destName}",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}