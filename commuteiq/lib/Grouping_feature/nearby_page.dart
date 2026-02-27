import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'ride_grouping_screen.dart'; 

class NearbyUsersPage extends StatefulWidget {
  final String destinationId;
  final String destinationName;
  final double destLat;
  final double destLng;

  const NearbyUsersPage({
    super.key,
    required this.destinationId,
    required this.destinationName,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<NearbyUsersPage> createState() => _NearbyUsersPageState();
}

class _NearbyUsersPageState extends State<NearbyUsersPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  String? myPhone; 
  List<Map<String, dynamic>> activeUsers = [];
  bool hasNavigatedToGroup = false;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    myPhone = prefs.getString('phone'); 

    if (myPhone == null || myPhone!.isEmpty) return;

    // 1. Mark yourself as Active immediately
    await dbRef.child("grouping/$myPhone").update({
      "phone": myPhone,
      "destinationId": widget.destinationId,
      "isActive": true,
      "lastSeen": ServerValue.timestamp,
    });

    // Cleanup: If the app closes, set active to false
    dbRef.child("grouping/$myPhone/isActive").onDisconnect().set(false);

    // 2. Start listeners
    listenForActiveUsers();
    listenForIncomingRequests();
  }

  // --- SHOW ALL USERS WHERE ISACTIVE == TRUE ---
  void listenForActiveUsers() {
    dbRef.child("grouping").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      List<Map<String, dynamic>> tempList = [];
      data.forEach((key, value) {
        if (key == myPhone) return; // Don't show myself
        
        final user = Map<String, dynamic>.from(value);
        
        // FILTER: Only show users who are ACTIVE and going to the SAME destination
        if (user["isActive"] == true && user["destinationId"] == widget.destinationId) {
          tempList.add({
            "phone": key,
            "status": "Online",
          });
        }
      });

      if (mounted) setState(() => activeUsers = tempList);
    });
  }

  void listenForIncomingRequests() {
    // Receiver Side: Someone sent a request to ME
    dbRef.child("rideRequests").orderByChild("to").equalTo(myPhone).onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data["status"] == "pending") {
        _showRequestDialog(event.snapshot.key!, data["from"]);
      }
    });

    // Sender/Receiver Side: The request was accepted
    dbRef.child("rideRequests").onChildChanged.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      bool involvesMe = data["from"] == myPhone || data["to"] == myPhone;
      
      if (involvesMe && data["status"] == "accepted" && !hasNavigatedToGroup) {
        _navigateToGroup(data["groupId"]);
      }
    });
  }

  void _navigateToGroup(String groupId) {
    hasNavigatedToGroup = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RideGroupScreen(groupId: groupId)),
    );
  }

  void _showRequestDialog(String requestId, String senderPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Ride Request"),
        content: Text("User $senderPhone is ready to go!"),
        actions: [
          TextButton(
            onPressed: () {
              dbRef.child("rideRequests/$requestId").update({"status": "rejected"});
              Navigator.pop(context);
            },
            child: const Text("DECLINE"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              String groupId = dbRef.child("rideGroups").push().key!;
              
              await dbRef.child("rideGroups/$groupId").set({
                "members": { myPhone!: true, senderPhone: true },
                "destination": widget.destinationId,
                "createdAt": ServerValue.timestamp,
              });

              await dbRef.child("rideRequests/$requestId").update({
                "status": "accepted",
                "groupId": groupId,
              });
            },
            child: const Text("ACCEPT"),
          ),
        ],
      ),
    );
  }

  Future<void> sendRideRequest(String receiverPhone) async {
    String requestId = dbRef.child("rideRequests").push().key!;
    await dbRef.child("rideRequests/$requestId").set({
      "from": myPhone,
      "to": receiverPhone,
      "status": "pending",
      "createdAt": ServerValue.timestamp,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Request sent to $receiverPhone")),
    );
  }

  @override
  void dispose() {
    if (myPhone != null) {
      dbRef.child("grouping/$myPhone").update({"isActive": false});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Going to ${widget.destinationName}"),
        backgroundColor: Colors.indigo,
      ),
      body: activeUsers.isEmpty 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Waiting for others to join..."),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final user = activeUsers[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.account_circle, size: 40, color: Colors.indigo),
                  title: Text(user['phone']),
                  subtitle: const Text("Status: Active", style: TextStyle(color: Colors.green)),
                  trailing: ElevatedButton(
                    onPressed: () => sendRideRequest(user['phone']),
                    child: const Text("Request"),
                  ),
                ),
              );
            },
          ),
    );
  }
}