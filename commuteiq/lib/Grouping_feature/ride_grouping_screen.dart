import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RideGroupScreen extends StatefulWidget {
  final String groupId;

  const RideGroupScreen({super.key, required this.groupId});

  @override
  State<RideGroupScreen> createState() => _RideGroupScreenState();
}

class _RideGroupScreenState extends State<RideGroupScreen> {
  final dbRef = FirebaseDatabase.instance.ref();
  bool dialogShown = false; // Prevents the dialog from popping up multiple times

  // This function updates the DB so EVERYONE sees the booking start
  void syncBookingStatus() async {
    await dbRef.child("rideGroups/${widget.groupId}").update({
      "status": "booking",
    });

    // Simulate backend processing for 3 seconds, then set to ready
    Future.delayed(const Duration(seconds: 3), () async {
      await dbRef.child("rideGroups/${widget.groupId}").update({
        "status": "ready",
      });
    });
  }

  void _showSyncDialog() {
    if (dialogShown) return;
    dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Booking shared ride for the group...",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Group"), backgroundColor: primary),
      body: StreamBuilder(
        stream: dbRef.child("rideGroups/${widget.groupId}").onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final members = Map<String, dynamic>.from(groupData['members'] ?? {});
          final String status = groupData['status'] ?? "waiting";

          // SYNC LOGIC: If 3 members joined and no one started booking yet
          if (members.length >= 3 && status == "waiting") {
            syncBookingStatus();
          }

          // UI SYNC: If status is 'booking', show dialog on ALL phones
          if (status == "booking") {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showSyncDialog());
          }

          // UI SYNC: If status is 'ready', close dialog on ALL phones
          if (status == "ready" && dialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
            dialogShown = false; 
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text("Group Members (${members.length}/3)", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ...members.keys.map((memberId) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text("User: $memberId"),
                      ),
                    )).toList(),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == "ready" ? Colors.green : primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: status == "ready" ? () {
                    // Navigate to payment
                  } : null, // Disable until group is ready
                  child: Text(
                    status == "ready" ? "Continue to Payment" : "Waiting for Group...",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}