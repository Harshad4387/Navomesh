import 'dart:async';
import 'package:flutter/material.dart';

enum LiftStatus { searching, driverFound, inProgress, reached }

class PaidLiftSimulationScreen extends StatefulWidget {
  const PaidLiftSimulationScreen({super.key});

  @override
  State<PaidLiftSimulationScreen> createState() => _PaidLiftSimulationScreenState();
}

class _PaidLiftSimulationScreenState extends State<PaidLiftSimulationScreen> {
  LiftStatus _currentStatus = LiftStatus.searching;

  @override
  void initState() {
    super.initState();
    // 1. Simulate searching for 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _currentStatus = LiftStatus.driverFound);
    });
  }

  void _startRide() {
    setState(() => _currentStatus = LiftStatus.inProgress);
    // 2. Simulate the actual trip for 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _currentStatus = LiftStatus.reached);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_currentStatus == LiftStatus.reached ? "Trip Completed" : "Paid Lift Finder"),
        backgroundColor: _currentStatus == LiftStatus.reached ? Colors.green.shade700 : Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentStatus) {
      case LiftStatus.searching:
        return _buildSearchingUI();
      case LiftStatus.driverFound:
        return _buildDriverFoundUI();
      case LiftStatus.inProgress:
        return _buildInProgressUI();
      case LiftStatus.reached:
        return _buildReachedUI();
    }
  }

  Widget _buildSearchingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent),
          const SizedBox(height: 25),
          const Text("Broadcasting your route...", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Alerting drivers nearby", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildDriverFoundUI() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Driver heading your way!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDriverCard(),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInProgressUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          const Text("Ride in Progress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Heading to your destination...", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 30),
          const LinearProgressIndicator(backgroundColor: Colors.white, valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildReachedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.shade100),
              child: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            ),
            const SizedBox(height: 30),
            const Text("You've Reached!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 10),
            const Text("Safe drop-off confirmed.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 30, backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=driver1")),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Vikram Rathore", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("White Honda City • 4.9 ★", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Text("₹60", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              ],
            ),
            const Divider(height: 30),
            const Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text("ETA: 4 mins away"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _startRide,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: const Text("ACCEPT & START LIFT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}