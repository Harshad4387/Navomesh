import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadSchedulesPage extends StatefulWidget {
  const UploadSchedulesPage({super.key});

  @override
  State<UploadSchedulesPage> createState() => _UploadSchedulesPageState();
}

class _UploadSchedulesPageState extends State<UploadSchedulesPage> {
  bool isUploading = false;
  String status = "Ready to upload";

  /// 🚆 Train Schedule Data
  final List<Map<String, dynamic>> trainSchedules = [
  {
    "train_id": "P-100",
    "line": "Purple",
    "direction": "Southbound",
    "scenario": "Off-Peak",
    "frequency_minutes": 10,
    "schedule": [
      { "station_name": "PCMC Bhavan", "arrival_time": null, "departure_time": "08:50:00" },
      { "station_name": "Sant Tukaram Nagar", "arrival_time": "08:52:00", "departure_time": "08:52:30" },
      { "station_name": "Bhosari (Nashik Phata)", "arrival_time": "08:54:30", "departure_time": "08:55:00" },
      { "station_name": "Kasarwadi", "arrival_time": "08:57:00", "departure_time": "08:57:30" },
      { "station_name": "Phugewadi", "arrival_time": "08:59:30", "departure_time": "09:00:00" },
      { "station_name": "Dapodi", "arrival_time": "09:02:00", "departure_time": "09:02:30" },
      { "station_name": "Bopodi", "arrival_time": "09:04:30", "departure_time": "09:05:00" },
      { "station_name": "Khadki", "arrival_time": "09:07:00", "departure_time": "09:07:30" },
      { "station_name": "Shivaji Nagar", "arrival_time": "09:09:30", "departure_time": "09:10:00" },
      { "station_name": "District Court", "arrival_time": "09:12:00", "departure_time": "09:13:30" },
      { "station_name": "Kasba Peth (Budhwar Peth)", "arrival_time": "09:15:30", "departure_time": "09:16:00" },
      { "station_name": "Mandai", "arrival_time": "09:18:00", "departure_time": "09:18:30" },
      { "station_name": "Swargate", "arrival_time": "09:20:30", "departure_time": null }
    ]
  },
  {
    "train_id": "P-101",
    "line": "Purple",
    "direction": "Southbound",
    "scenario": "Peak",
    "frequency_minutes": 6,
    "schedule": [
      { "station_name": "PCMC Bhavan", "arrival_time": null, "departure_time": "09:00:00" },
      { "station_name": "Sant Tukaram Nagar", "arrival_time": "09:02:00", "departure_time": "09:02:30" },
      { "station_name": "Bhosari (Nashik Phata)", "arrival_time": "09:04:30", "departure_time": "09:05:00" },
      { "station_name": "Kasarwadi", "arrival_time": "09:07:00", "departure_time": "09:07:30" },
      { "station_name": "Phugewadi", "arrival_time": "09:09:30", "departure_time": "09:10:00" },
      { "station_name": "Dapodi", "arrival_time": "09:12:00", "departure_time": "09:12:30" },
      { "station_name": "Bopodi", "arrival_time": "09:14:30", "departure_time": "09:15:00" },
      { "station_name": "Khadki", "arrival_time": "09:17:00", "departure_time": "09:17:30" },
      { "station_name": "Shivaji Nagar", "arrival_time": "09:19:30", "departure_time": "09:20:00" },
      { "station_name": "District Court", "arrival_time": "09:22:00", "departure_time": "09:23:30" },
      { "station_name": "Kasba Peth (Budhwar Peth)", "arrival_time": "09:25:30", "departure_time": "09:26:00" },
      { "station_name": "Mandai", "arrival_time": "09:28:00", "departure_time": "09:28:30" },
      { "station_name": "Swargate", "arrival_time": "09:30:30", "departure_time": null }
    ]
  },
  {
    "train_id": "P-102",
    "line": "Purple",
    "direction": "Northbound",
    "scenario": "Off-Peak",
    "frequency_minutes": 10,
    "schedule": [
      { "station_name": "Swargate", "arrival_time": null, "departure_time": "08:50:00" },
      { "station_name": "Mandai", "arrival_time": "08:52:00", "departure_time": "08:52:30" },
      { "station_name": "Kasba Peth (Budhwar Peth)", "arrival_time": "08:54:30", "departure_time": "08:55:00" },
      { "station_name": "District Court", "arrival_time": "08:57:00", "departure_time": "08:58:30" },
      { "station_name": "Shivaji Nagar", "arrival_time": "09:00:30", "departure_time": "09:01:00" },
      { "station_name": "Khadki", "arrival_time": "09:03:00", "departure_time": "09:03:30" },
      { "station_name": "Bopodi", "arrival_time": "09:05:30", "departure_time": "09:06:00" },
      { "station_name": "Dapodi", "arrival_time": "09:08:00", "departure_time": "09:08:30" },
      { "station_name": "Phugewadi", "arrival_time": "09:10:30", "departure_time": "09:11:00" },
      { "station_name": "Kasarwadi", "arrival_time": "09:13:00", "departure_time": "09:13:30" },
      { "station_name": "Bhosari (Nashik Phata)", "arrival_time": "09:15:30", "departure_time": "09:16:00" },
      { "station_name": "Sant Tukaram Nagar", "arrival_time": "09:18:00", "departure_time": "09:18:30" },
      { "station_name": "PCMC Bhavan", "arrival_time": "09:20:30", "departure_time": null }
    ]
  },
  {
    "train_id": "P-103",
    "line": "Purple",
    "direction": "Northbound",
    "scenario": "Peak",
    "frequency_minutes": 6,
    "schedule": [
      { "station_name": "Swargate", "arrival_time": null, "departure_time": "09:00:00" },
      { "station_name": "Mandai", "arrival_time": "09:02:00", "departure_time": "09:02:30" },
      { "station_name": "Kasba Peth (Budhwar Peth)", "arrival_time": "09:04:30", "departure_time": "09:05:00" },
      { "station_name": "District Court", "arrival_time": "09:07:00", "departure_time": "09:08:30" },
      { "station_name": "Shivaji Nagar", "arrival_time": "09:10:30", "departure_time": "09:11:00" },
      { "station_name": "Khadki", "arrival_time": "09:13:00", "departure_time": "09:13:30" },
      { "station_name": "Bopodi", "arrival_time": "09:15:30", "departure_time": "09:16:00" },
      { "station_name": "Dapodi", "arrival_time": "09:18:00", "departure_time": "09:18:30" },
      { "station_name": "Phugewadi", "arrival_time": "09:20:30", "departure_time": "09:21:00" },
      { "station_name": "Kasarwadi", "arrival_time": "09:23:00", "departure_time": "09:23:30" },
      { "station_name": "Bhosari (Nashik Phata)", "arrival_time": "09:25:30", "departure_time": "09:26:00" },
      { "station_name": "Sant Tukaram Nagar", "arrival_time": "09:28:00", "departure_time": "09:28:30" },
      { "station_name": "PCMC Bhavan", "arrival_time": "09:30:30", "departure_time": null }
    ]
  },
  {
    "train_id": "A-200",
    "line": "Aqua",
    "direction": "Eastbound",
    "scenario": "Off-Peak",
    "frequency_minutes": 10,
    "schedule": [
      { "station_name": "Vanaz", "arrival_time": null, "departure_time": "15:50:00" },
      { "station_name": "Anand Nagar", "arrival_time": "15:52:00", "departure_time": "15:52:30" },
      { "station_name": "Ideal Colony", "arrival_time": "15:54:30", "departure_time": "15:55:00" },
      { "station_name": "Nal Stop", "arrival_time": "15:57:00", "departure_time": "15:57:30" },
      { "station_name": "Garware College", "arrival_time": "15:59:30", "departure_time": "16:00:00" },
      { "station_name": "Deccan Gymkhana", "arrival_time": "16:02:00", "departure_time": "16:02:30" },
      { "station_name": "Chhatrapati Sambhaji Udyan", "arrival_time": "16:04:30", "departure_time": "16:05:00" },
      { "station_name": "PMC Bhavan", "arrival_time": "16:07:00", "departure_time": "16:07:30" },
      { "station_name": "District Court", "arrival_time": "16:09:30", "departure_time": "16:11:00" },
      { "station_name": "Mangalwar Peth (RTO)", "arrival_time": "16:13:30", "departure_time": "16:14:00" },
      { "station_name": "Pune Railway Station", "arrival_time": "16:16:00", "departure_time": "16:16:30" },
      { "station_name": "Ruby Hall Clinic", "arrival_time": "16:18:30", "departure_time": "16:19:00" },
      { "station_name": "Bund Garden", "arrival_time": "16:21:00", "departure_time": "16:21:30" },
      { "station_name": "Yerawada", "arrival_time": "16:23:30", "departure_time": "16:24:00" },
      { "station_name": "Kalyani Nagar", "arrival_time": "16:26:00", "departure_time": "16:26:30" },
      { "station_name": "Ramwadi", "arrival_time": "16:29:00", "departure_time": null }
    ]
  },
  {
    "train_id": "A-201",
    "line": "Aqua",
    "direction": "Eastbound",
    "scenario": "Peak",
    "frequency_minutes": 6,
    "schedule": [
      { "station_name": "Vanaz", "arrival_time": null, "departure_time": "16:00:00" },
      { "station_name": "Anand Nagar", "arrival_time": "16:02:00", "departure_time": "16:02:30" },
      { "station_name": "Ideal Colony", "arrival_time": "16:04:30", "departure_time": "16:05:00" },
      { "station_name": "Nal Stop", "arrival_time": "16:07:00", "departure_time": "16:07:30" },
      { "station_name": "Garware College", "arrival_time": "16:09:30", "departure_time": "16:10:00" },
      { "station_name": "Deccan Gymkhana", "arrival_time": "16:12:00", "departure_time": "16:12:30" },
      { "station_name": "Chhatrapati Sambhaji Udyan", "arrival_time": "16:14:30", "departure_time": "16:15:00" },
      { "station_name": "PMC Bhavan", "arrival_time": "16:17:00", "departure_time": "16:17:30" },
      { "station_name": "District Court", "arrival_time": "16:19:30", "departure_time": "16:21:00" },
      { "station_name": "Mangalwar Peth (RTO)", "arrival_time": "16:23:30", "departure_time": "16:24:00" },
      { "station_name": "Pune Railway Station", "arrival_time": "16:26:00", "departure_time": "16:26:30" },
      { "station_name": "Ruby Hall Clinic", "arrival_time": "16:28:30", "departure_time": "16:29:00" },
      { "station_name": "Bund Garden", "arrival_time": "16:31:00", "departure_time": "16:31:30" },
      { "station_name": "Yerawada", "arrival_time": "16:33:30", "departure_time": "16:34:00" },
      { "station_name": "Kalyani Nagar", "arrival_time": "16:36:00", "departure_time": "16:36:30" },
      { "station_name": "Ramwadi", "arrival_time": "16:39:00", "departure_time": null }
    ]
  },
  {
    "train_id": "A-202",
    "line": "Aqua",
    "direction": "Westbound",
    "scenario": "Off-Peak",
    "frequency_minutes": 10,
    "schedule": [
      { "station_name": "Ramwadi", "arrival_time": null, "departure_time": "15:50:00" },
      { "station_name": "Kalyani Nagar", "arrival_time": "15:52:00", "departure_time": "15:52:30" },
      { "station_name": "Yerawada", "arrival_time": "15:54:30", "departure_time": "15:55:00" },
      { "station_name": "Bund Garden", "arrival_time": "15:57:00", "departure_time": "15:57:30" },
      { "station_name": "Ruby Hall Clinic", "arrival_time": "15:59:30", "departure_time": "16:00:00" },
      { "station_name": "Pune Railway Station", "arrival_time": "16:02:00", "departure_time": "16:02:30" },
      { "station_name": "Mangalwar Peth (RTO)", "arrival_time": "16:04:30", "departure_time": "16:05:00" },
      { "station_name": "District Court", "arrival_time": "16:07:00", "departure_time": "16:08:30" },
      { "station_name": "PMC Bhavan", "arrival_time": "16:10:30", "departure_time": "16:11:00" },
      { "station_name": "Chhatrapati Sambhaji Udyan", "arrival_time": "16:13:00", "departure_time": "16:13:30" },
      { "station_name": "Deccan Gymkhana", "arrival_time": "16:15:30", "departure_time": "16:16:00" },
      { "station_name": "Garware College", "arrival_time": "16:18:00", "departure_time": "16:18:30" },
      { "station_name": "Nal Stop", "arrival_time": "16:20:30", "departure_time": "16:21:00" },
      { "station_name": "Ideal Colony", "arrival_time": "16:23:00", "departure_time": "16:23:30" },
      { "station_name": "Anand Nagar", "arrival_time": "16:25:30", "departure_time": "16:26:00" },
      { "station_name": "Vanaz", "arrival_time": "16:28:00", "departure_time": null }
    ]
  },
  {
    "train_id": "A-203",
    "line": "Aqua",
    "direction": "Westbound",
    "scenario": "Peak",
    "frequency_minutes": 6,
    "schedule": [
      { "station_name": "Ramwadi", "arrival_time": null, "departure_time": "16:00:00" },
      { "station_name": "Kalyani Nagar", "arrival_time": "16:02:00", "departure_time": "16:02:30" },
      { "station_name": "Yerawada", "arrival_time": "16:04:30", "departure_time": "16:05:00" },
      { "station_name": "Bund Garden", "arrival_time": "16:07:00", "departure_time": "16:07:30" },
      { "station_name": "Ruby Hall Clinic", "arrival_time": "16:09:30", "departure_time": "16:10:00" },
      { "station_name": "Pune Railway Station", "arrival_time": "16:12:00", "departure_time": "16:12:30" },
      { "station_name": "Mangalwar Peth (RTO)", "arrival_time": "16:14:30", "departure_time": "16:15:00" },
      { "station_name": "District Court", "arrival_time": "16:17:00", "departure_time": "16:18:30" },
      { "station_name": "PMC Bhavan", "arrival_time": "16:20:30", "departure_time": "16:21:00" },
      { "station_name": "Chhatrapati Sambhaji Udyan", "arrival_time": "16:23:00", "departure_time": "16:23:30" },
      { "station_name": "Deccan Gymkhana", "arrival_time": "16:25:30", "departure_time": "16:26:00" },
      { "station_name": "Garware College", "arrival_time": "16:28:00", "departure_time": "16:28:30" },
      { "station_name": "Nal Stop", "arrival_time": "16:30:30", "departure_time": "16:31:00" },
      { "station_name": "Ideal Colony", "arrival_time": "16:33:00", "departure_time": "16:33:30" },
      { "station_name": "Anand Nagar", "arrival_time": "16:35:30", "departure_time": "16:36:00" },
      { "station_name": "Vanaz", "arrival_time": "16:38:00", "departure_time": null }
    ]
  }



];

  /// 🚀 Upload Function
  Future<void> uploadSchedules() async {
  setState(() {
    isUploading = true;
    status = "Starting upload...";
  });

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  try {
    final collectionRef = firestore.collection('train_schedules');

    for (var train in trainSchedules) {
      final trainRef = collectionRef.doc(train['train_id']);

      /// ✅ Store full schedule array in main document
      batch.set(trainRef, {
        'train_id': train['train_id'],
        'line': train['line'],
        'direction': train['direction'],
        'scenario': train['scenario'],
        'frequency_minutes': train['frequency_minutes'],
        'total_stops': train['schedule'].length,
        'schedule': train['schedule'], // 🔥 FULL schedule stored
        'created_at': FieldValue.serverTimestamp(),
      });

      /// ✅ Also store stops in subcollection (optional but powerful)
      for (var stop in train['schedule']) {
        String stationId =
            stop['station_name'].toString().replaceAll('/', '-');

        final stopRef = trainRef.collection('stops').doc(stationId);

        batch.set(stopRef, {
          'station_name': stop['station_name'],
          'arrival_time': stop['arrival_time'],
          'departure_time': stop['departure_time'],
        });
      }
    }

    await batch.commit();

    setState(() {
      status = "✅ Uploaded ${trainSchedules.length} trains with schedules!";
    });
  } catch (e) {
    setState(() {
      status = "❌ Error: $e";
    });
  } finally {
    setState(() => isUploading = false);
  }
}

  /// 🎨 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Train Schedules")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUploading ? Icons.cloud_sync : Icons.train,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: isUploading ? null : uploadSchedules,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Data to Firestore"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}