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

  // Map stores MAC address as Key and Device Name as Value

  // This ensures unique MACs while keeping names accessible

  Map<String, String> detectedDevices = {};

  bool isScanning = false;

 

  // Threshold for crowd detection

  final int crowdThreshold = 15;

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;



  @override

  void initState() {

    super.initState();

    _requestPermissions();

  }



  Future<void> _requestPermissions() async {

    await [

      Permission.bluetoothScan,

      Permission.bluetoothConnect,

      Permission.location,

    ].request();

  }



  void startCrowdScan() async {

    setState(() {

      detectedDevices.clear();

      isScanning = true;

    });



    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {

      for (ScanResult r in results) {

        // Tighter RSSI Filtering:

        // -50 to -55 dBm is roughly 1 meter.

        if (r.rssi > -55) {

          String mac = r.device.remoteId.str;

          // Use platformName if available, otherwise 'Unknown'

          String name = r.device.platformName.isNotEmpty

              ? r.device.platformName

              : "Unknown Device";



          setState(() {

            detectedDevices[mac] = name;

          });

        }

      }

    });



    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

   

    setState(() {

      isScanning = false;

    });

  }



  void stopCrowdScan() async {

    await FlutterBluePlus.stopScan();

    setState(() {

      isScanning = false;

    });

  }



  @override

  void dispose() {

    // Check if initialized before canceling to avoid errors

    _scanResultsSubscription.cancel();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    bool isCrowdGathered = detectedDevices.length >= crowdThreshold;



    return Scaffold(

      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(

        title: const Text('Crowd Detector'),

        backgroundColor: Colors.indigo[900],

        foregroundColor: Colors.white,

      ),

      body: Column(

        children: [

          const SizedBox(height: 30),

          // --- Status Header ---

          _buildStatusHeader(isCrowdGathered),

         

          const Divider(height: 40, thickness: 1),

         

          // --- Real-time List of Names and MACs ---

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                const Text("Devices within 1m:", style: TextStyle(fontWeight: FontWeight.bold)),

                Text("${detectedDevices.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),

              ],

            ),

          ),

         

          Expanded(

            child: detectedDevices.isEmpty

              ? _buildEmptyState()

              : ListView.builder(

                  padding: const EdgeInsets.all(15),

                  itemCount: detectedDevices.length,

                  itemBuilder: (context, index) {

                    String mac = detectedDevices.keys.elementAt(index);

                    String name = detectedDevices[mac]!;

                    return Card(

                      elevation: 0,

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(10),

                        side: BorderSide(color: Colors.grey[200]!)

                      ),

                      child: ListTile(

                        leading: const CircleAvatar(

                          backgroundColor: Color(0xFFE8EAF6),

                          child: Icon(Icons.bluetooth, color: Colors.indigo, size: 20),

                        ),

                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),

                        subtitle: Text(mac, style: const TextStyle(fontSize: 12, color: Colors.grey)),

                        trailing: const Text("< 1m", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),

                      ),

                    );

                  },

                ),

          ),



          // --- Controls ---

          Padding(

            padding: const EdgeInsets.all(20.0),

            child: SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton.icon(

                onPressed: isScanning ? stopCrowdScan : startCrowdScan,

                icon: Icon(isScanning ? Icons.stop : Icons.search),

                label: Text(isScanning ? 'Scanning Environment...' : 'Scan Near Me (1m)'),

                style: ElevatedButton.styleFrom(

                  backgroundColor: isScanning ? Colors.red : Colors.indigo[900],

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),


                ),

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildStatusHeader(bool isCrowd) {

    return Column(

      children: [

        Icon(

          isCrowd ? Icons.groups_rounded : Icons.person_rounded,

          size: 80,

          color: isCrowd ? Colors.red : Colors.green,

        ),

        const SizedBox(height: 10),

        Text(

          isCrowd ? "CROWD DETECTED" : "CLEAR RADIUS",

          style: TextStyle(

            fontSize: 22,

            fontWeight: FontWeight.bold,

            color: isCrowd ? Colors.red : Colors.green,

          ),

        ),

      ],

    );

  }



  Widget _buildEmptyState() {

    return Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(Icons.radar, size: 50, color: Colors.grey[300]),

          const SizedBox(height: 10),

          Text("No devices found in 1m range", style: TextStyle(color: Colors.grey[400])),

        ],

      ),

    );

  }

}