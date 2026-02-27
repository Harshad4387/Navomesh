import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:async';

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------
class RideGroup {
  final String title;
  final List<Map<String, dynamic>> vehicles;

  RideGroup({required this.title, required this.vehicles});
}

class MetroStation {
  final String name;
  final double lat;
  final double lon;

  MetroStation(this.name, this.lat, this.lon);
}

// -----------------------------------------------------------------------------
// MAIN WIDGET
// -----------------------------------------------------------------------------
class MetroBookingScreen extends StatefulWidget {
  const MetroBookingScreen({Key? key}) : super(key: key);

  @override
  _MetroBookingScreenState createState() => _MetroBookingScreenState();
}

class _MetroBookingScreenState extends State<MetroBookingScreen> {
  // 1. All Pune Metro Stations
  final List<MetroStation> stations = [
    MetroStation("PCMC", 18.6298, 73.7997),
    MetroStation("Sant Tukaram Nagar", 18.6180, 73.8056),
    MetroStation("Bhosari", 18.6110, 73.8120),
    MetroStation("Kasarwadi", 18.6030, 73.8200),
    MetroStation("Phugewadi", 18.5950, 73.8270),
    MetroStation("Dapodi", 18.5830, 73.8340),
    MetroStation("Bopodi", 18.5720, 73.8410),
    MetroStation("Shivajinagar", 18.5314, 73.8552),
    MetroStation("Civil Court", 18.5285, 73.8565),
    MetroStation("Pune Railway Station", 18.5289, 73.8744),
    MetroStation("Ruby Hall Clinic", 18.5330, 73.8810),
    MetroStation("Bund Garden", 18.5360, 73.8870),
    MetroStation("Kalyani Nagar", 18.5482, 73.9015),
    MetroStation("Ramwadi", 18.5530, 73.9120),
  ];

  MetroStation? selectedSource;
  MetroStation? selectedDestination;

  bool isJourneyActive = false;
  String journeyStatus = "Select stations to synchronize journey";
  double journeyProgress = 0.0;
  Timer? journeyTimer;

  bool isLoading = false;
  bool isOptimized = false;
  List<RideGroup> displayGroups = [];

  // ✅ Pune Metro Branding Colors
  final Color puneMetroTeal = const Color(0xFF007A91); // Aqua Line Identity
  final Color puneMetroPurple = const Color(0xFF6A2B86); // Purple Line Identity

  @override
  void initState() {
    super.initState();
    selectedSource = stations[0]; 
    selectedDestination = stations[7]; 
  }

  @override
  void dispose() {
    journeyTimer?.cancel();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; 
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  List<Map<String, dynamic>> _generateDriversNear(MetroStation destination) {
    final random = math.Random();
    List<Map<String, dynamic>> generatedDrivers = [];
    List<String> companies = ['ola', 'uber', 'rapido', 'namma yatri'];
    List<String> types = ['cab', 'bike', 'rickshaw'];

    for (int i = 0; i < 15; i++) {
      double latOffset = (random.nextDouble() - 0.5) * 0.03;
      double lonOffset = (random.nextDouble() - 0.5) * 0.03;
      double driverLat = destination.lat + latOffset;
      double driverLon = destination.lon + lonOffset;

      double distKm = _calculateDistance(driverLat, driverLon, destination.lat, destination.lon);
      int etaMins = ((distKm / 25.0) * 60).round();
      if (etaMins < 1) etaMins = 1; 

      String type = types[random.nextInt(types.length)];
      String company = companies[random.nextInt(companies.length)];

      generatedDrivers.add({
        "name": "$type-${random.nextInt(900) + 100}",
        "company": company,
        "type": type,
        "eta": etaMins, 
        "dist": double.parse(distKm.toStringAsFixed(1)),
        "fare": (distKm * 15 + 30).round(), 
      });
    }
    generatedDrivers.sort((a, b) => (a['eta'] as int).compareTo(b['eta'] as int));
    return generatedDrivers;
  }

  void _startJourneySimulation() {
    if (selectedSource == null || selectedDestination == null) return;
    if (selectedSource == selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and Destination cannot be the same!')),
      );
      return;
    }

    double journeyDistKm = _calculateDistance(selectedSource!.lat, selectedSource!.lon, selectedDestination!.lat, selectedDestination!.lon);
    int totalJourneyMins = ((journeyDistKm / 35.0) * 60).round();
    if (totalJourneyMins < 6) totalJourneyMins = 8; 

    int driverBufferMins = 5;
    int triggerTimeMins = totalJourneyMins - driverBufferMins;

    setState(() {
      isJourneyActive = true;
      journeyProgress = 0.0;
      journeyStatus = "Traveling: ${selectedSource!.name} ➔ ${selectedDestination!.name}";
      displayGroups.clear(); 
    });

    int currentSimulatedMin = 0;
    journeyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentSimulatedMin++;
      setState(() {
        journeyProgress = currentSimulatedMin / totalJourneyMins;
        if (totalJourneyMins - currentSimulatedMin > 0) {
          journeyStatus = "In Transit... Arriving in ${totalJourneyMins - currentSimulatedMin} mins";
        }
      });

      if (currentSimulatedMin == triggerTimeMins) {
        timer.cancel(); 
        _showSmartBookingPrompt(selectedDestination!, totalJourneyMins - currentSimulatedMin);
      }
    });
  }

  void _showSmartBookingPrompt(MetroStation destination, int minsRemaining) {
    List<Map<String, dynamic>> nearbyDrivers = _generateDriversNear(destination);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: puneMetroPurple, size: 28),
              const SizedBox(width: 10),
              const Text("Smart Sync", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Arriving at ${destination.name} in $minsRemaining mins.", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: puneMetroTeal.withOpacity(0.3))),
                child: Text("We found ${nearbyDrivers.length} drivers timed for your arrival. Book now to eliminate wait time.",
                    style: TextStyle(color: puneMetroTeal, fontSize: 13, fontWeight: FontWeight.w500)),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () { Navigator.of(context).pop(); _finishJourney(); }, child: const Text("I'll wait", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: puneMetroPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () { Navigator.of(context).pop(); _processBookings(nearbyDrivers); _finishJourney(); },
              child: const Text("Show Rides"),
            ),
          ],
        );
      },
    );
  }

  void _processBookings(List<Map<String, dynamic>> rawDrivers) {
    setState(() { isLoading = true; });
    Future.delayed(const Duration(seconds: 1), () {
      List<RideGroup> newGroups = [];
      List<Map<String, dynamic>> perfectMatches = rawDrivers.where((d) => d['eta'] <= 5).toList();
      if (perfectMatches.isNotEmpty) {
        newGroups.add(RideGroup(title: "⚡ FASTEST SYNC (0-5 min wait)", vehicles: perfectMatches));
      }
      List<Map<String, dynamic>> others = rawDrivers.where((d) => d['eta'] > 5).toList();
      if (others.isNotEmpty) {
        newGroups.add(RideGroup(title: "🕒 SLIGHT WAIT (5+ min wait)", vehicles: others));
      }
      setState(() { displayGroups = newGroups; isLoading = false; isOptimized = true; });
    });
  }

  void _finishJourney() {
    setState(() { journeyProgress = 1.0; journeyStatus = "Arrived at ${selectedDestination!.name}!"; isJourneyActive = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Metro Sync Engine", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: puneMetroTeal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                color: puneMetroTeal,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<MetroStation>(
                            value: selectedSource,
                            isExpanded: true,
                            items: stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                            onChanged: isJourneyActive ? null : (val) => setState(() => selectedSource = val),
                          ),
                        ),
                      ),
                      Icon(Icons.sync_alt, color: puneMetroPurple),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<MetroStation>(
                            value: selectedDestination,
                            isExpanded: true,
                            items: stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                            onChanged: isJourneyActive ? null : (val) => setState(() => selectedDestination = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (isJourneyActive || journeyProgress == 1.0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: journeyProgress,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(journeyStatus, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJourneyActive ? puneMetroPurple : Colors.white,
                    foregroundColor: isJourneyActive ? Colors.white : puneMetroTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isJourneyActive ? () { journeyTimer?.cancel(); setState(() => isJourneyActive = false); } : _startJourneySimulation,
                  icon: Icon(isJourneyActive ? Icons.stop_circle : Icons.bolt),
                  label: Text(isJourneyActive ? "Stop Simulation" : "Start Journey Sync", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (isLoading) Expanded(child: Center(child: CircularProgressIndicator(color: puneMetroTeal))),
          if (!isLoading && displayGroups.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: displayGroups.length,
                itemBuilder: (context, groupIndex) {
                  final group = displayGroups[groupIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(group.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: puneMetroPurple, letterSpacing: 0.5)),
                      ),
                      ...group.vehicles.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
                    ],
                  );
                },
              ),
            ),
          if (!isLoading && displayGroups.isEmpty && !isJourneyActive)
            const Expanded(child: Center(child: Text("Select stations and start sync to view rides.", style: TextStyle(color: Colors.grey, fontSize: 14)))),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(15)),
              child: Icon(_getIconForType(vehicle["type"]), color: puneMetroTeal, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle["name"].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(vehicle["company"].toString().toUpperCase(), style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text("${vehicle['eta']} min away", style: TextStyle(color: puneMetroPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: puneMetroPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(70, 35),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking ${vehicle["name"]}... Driver synchronized with your arrival!')));
              },
              child: const Text("Sync", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'cab': return Icons.directions_car;
      case 'bike': return Icons.two_wheeler;
      case 'rickshaw': return Icons.electric_rickshaw;
      default: return Icons.commute;
    }
  }

  Future<void> _openRideApp(String company) async {
    Uri url;
    switch (company.toLowerCase()) {
      case 'ola': url = Uri.parse('https://book.olacabs.com/'); break;
      case 'uber': url = Uri.parse('https://m.uber.com/'); break;
      case 'rapido': url = Uri.parse('https://www.rapido.bike/'); break;
      case 'namma yatri': url = Uri.parse('https://nammayatri.in/'); break;
      default: return;
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}