import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadMetroDataPage extends StatelessWidget {
  UploadMetroDataPage({super.key});

  // 📍 Metro data
  final List<Map<String, dynamic>> metroStations = [
    {
      "name of station": "PCMC Bhavan",
      "coords": [18.6294, 73.8033],
      "line": "Purple",
    },
    {
      "name of station": "Sant Tukaram Nagar",
      "coords": [18.6146, 73.8158],
      "line": "Purple",
    },
    {
      "name of station": "Bhosari (Nashik Phata)",
      "coords": [18.6053, 73.8217],
      "line": "Purple",
    },
    {
      "name of station": "Kasarwadi",
      "coords": [18.5959, 73.8247],
      "line": "Purple",
    },
    {
      "name of station": "Phugewadi",
      "coords": [18.5847, 73.8273],
      "line": "Purple",
    },
    {
      "name of station": "Dapodi",
      "coords": [18.5772, 73.8341],
      "line": "Purple",
    },
    {
      "name of station": "Bopodi",
      "coords": [18.5663, 73.8398],
      "line": "Purple",
    },
    {
      "name of station": "Khadki",
      "coords": [18.5583, 73.8441],
      "line": "Purple",
    },
    {
      "name of station": "Shivaji Nagar",
      "coords": [18.5323, 73.8488],
      "line": "Purple",
    },
    {
      "name of station": "Kasba Peth (Budhwar Peth)",
      "coords": [18.5198, 73.8565],
      "line": "Purple",
    },
    {
      "name of station": "Mandai",
      "coords": [18.5113, 73.8552],
      "line": "Purple",
    },
    {
      "name of station": "Swargate",
      "coords": [18.5020, 73.8561],
      "line": "Purple",
    },
    {
      "name of station": "Vanaz",
      "coords": [18.5072, 73.8052],
      "line": "Aqua",
    },
    {
      "name of station": "Anand Nagar",
      "coords": [18.5057, 73.8130],
      "line": "Aqua",
    },
    {
      "name of station": "Ideal Colony",
      "coords": [18.5042, 73.8208],
      "line": "Aqua",
    },
    {
      "name of station": "Nal Stop",
      "coords": [18.5065, 73.8267],
      "line": "Aqua",
    },
    {
      "name of station": "Garware College",
      "coords": [18.5106, 73.8364],
      "line": "Aqua",
    },
    {
      "name of station": "Deccan Gymkhana",
      "coords": [18.5144, 73.8415],
      "line": "Aqua",
    },
    {
      "name of station": "Chhatrapati Sambhaji Udyan",
      "coords": [18.5165, 73.8460],
      "line": "Aqua",
    },
    {
      "name of station": "PMC Bhavan",
      "coords": [18.5218, 73.8523],
      "line": "Aqua",
    },
    {
      "name of station": "Mangalwar Peth (RTO)",
      "coords": [18.5305, 73.8687],
      "line": "Aqua",
    },
    {
      "name of station": "Pune Railway Station",
      "coords": [18.5273, 73.8736],
      "line": "Aqua",
    },
    {
      "name of station": "Ruby Hall Clinic",
      "coords": [18.5327, 73.8789],
      "line": "Aqua",
    },
    {
      "name of station": "Bund Garden",
      "coords": [18.5367, 73.8824],
      "line": "Aqua",
    },
    {
      "name of station": "Yerawada",
      "coords": [18.5501, 73.8893],
      "line": "Aqua",
    },
    {
      "name of station": "Kalyani Nagar",
      "coords": [18.5475, 73.9015],
      "line": "Aqua",
    },
    {
      "name of station": "Ramwadi",
      "coords": [18.5532, 73.9168],
      "line": "Aqua",
    },
    {
      "name of station": "District Court",
      "coords": [18.5269, 73.8580],
      "line": "Purple and Aqua",
    },
  ];

  Future<void> uploadData(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    for (var station in metroStations) {
      await firestore
          .collection('MetroLocations')
          .doc(
            station['name of station'], // ✅ use correct key
          )
          .set({
            'name': station['name of station'], // ✅ correct key
            'latitude': station['coords'][0], // ✅ from coords
            'longitude': station['coords'][1], // ✅ from coords
            'line': station['line'],
          });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Metro data uploaded successfully 🚀")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Metro Data')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => uploadData(context),
          child: const Text("Upload to Firestore"),
        ),
      ),
    );
  }
}
