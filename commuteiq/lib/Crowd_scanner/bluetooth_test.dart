import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class CrowdScannerScreen extends StatefulWidget {
  const CrowdScannerScreen({super.key});

  @override
  State<CrowdScannerScreen> createState() => _CrowdScannerScreenState();
}

class _CrowdScannerScreenState extends State<CrowdScannerScreen> {
  // A Set automatically rejects duplicate Bluetooth IDs
  Set<String> uniqueDevices = {};
  bool isScanning = false;
  
  // Set your crowd threshold here. If we see more than 15 devices, it's a crowd.
  final int crowdThreshold = 15; 
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // 1. Ask the user for permission to use Bluetooth
  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationFine, // Required by Android to scan for BLE
    ].request();
  }

  // 2. Start the crowd detection scan
  void startCrowdScan() async {
    // Clear previous data for a fresh count
    setState(() {
      uniqueDevices.clear();
      isScanning = true;
    });

    // Listen to the scanner stream
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // remoteId is the unique MAC address (Android) or UUID (iOS)
        setState(() {
          uniqueDevices.add(r.device.remoteId.str);
        });
      }
    });

    // Start scanning for 15 seconds. It will stop automatically.
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    // Once the scan finishes, update the UI state
    setState(() {
      isScanning = false;
    });
  }

  // 3. Manually stop the scan if needed
  void stopCrowdScan() async {
    await FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCrowdGathered = uniqueDevices.length >= crowdThreshold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crowd Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display Crowd Status
            Icon(
              isCrowdGathered ? Icons.groups : Icons.person,
              size: 100,
              color: isCrowdGathered ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              isCrowdGathered ? "CROWD DETECTED" : "CLEAR",
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: isCrowdGathered ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            
            // Display Device Count
            Text(
              'Unique Devices Found:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${uniqueDevices.length}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 40),
            
            // Start/Stop Button
            ElevatedButton.icon(
              onPressed: isScanning ? stopCrowdScan : startCrowdScan,
              icon: Icon(isScanning ? Icons.stop : Icons.search),
              label: Text(isScanning ? 'Scanning...' : 'Detect Crowd (15s)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

