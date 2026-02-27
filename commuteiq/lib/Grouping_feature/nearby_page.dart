import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// Note: We only need Firebase Database, not Auth
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
  StreamSubscription<Position>? positionStream;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  String? myPhone; // This will be our primary key (Document ID)
  double? myLat;
  double? myLng;
  List<Map<String, dynamic>> nearbyUsers = [];
  bool hasNavigatedToGroup = false;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    // 1. Get Phone from SharedPreferences (Matching your RegisterPage key)
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    myPhone = prefs.getString('phone'); 

    if (myPhone == null || myPhone!.isEmpty) {
      // If no phone found, the user isn't registered. 
      // You might want to redirect them to RegisterPage here.
      debugPrint("User not registered. No phone found in storage.");
      return;
    }

    // 2. Add user to the live 'grouping' node immediately
    await checkAndAddUserToGrouping();

    // 3. Start tracking and listening
    startLocationTracking();
    listenForNearbyUsers();
    listenForIncomingRequests();
  }

  // --- DATABASE INITIALIZATION ---

  Future<void> checkAndAddUserToGrouping() async {
    if (myPhone == null) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    myLat = position.latitude;
    myLng = position.longitude;

    // We store under 'grouping/phone_number'
    // This makes the user "live" as soon as they land on this page
    await dbRef.child("grouping/$myPhone").update({
      "phone": myPhone,
      "lat": myLat,
      "long": myLng,
      "destinationId": widget.destinationId,
      "isActive": true,
      "lastSeen": ServerValue.timestamp,
    });

    // Cleanup: If the app closes/crashes, mark them inactive
    dbRef.child("grouping/$myPhone/isActive").onDisconnect().set(false);
  }

  // --- REAL-TIME LOCATION & FILTERING ---

  Future<void> startLocationTracking() async {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 5 // Updates every 5 meters
      ),
    ).listen((Position position) {
      myLat = position.latitude;
      myLng = position.longitude;

      if (myPhone != null) {
        dbRef.child("grouping/$myPhone").update({
          "lat": myLat,
          "long": myLng,
          "lastSeen": ServerValue.timestamp,
        });
      }
      if (mounted) setState(() {});
    });
  }

  void listenForNearbyUsers() {
    dbRef.child("grouping").onValue.listen((event) {
      if (myLat == null || myLng == null) return;
      
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      List<Map<String, dynamic>> tempList = [];
      data.forEach((key, value) {
        if (key == myPhone) return; // Skip self
        
        final user = Map<String, dynamic>.from(value);
        
        // Filter: Active users going to the SAME destination
        if (user["isActive"] == true && user["destinationId"] == widget.destinationId) {
          double distance = calculateDistance(myLat!, myLng!, user["lat"], user["long"]);
          
          // Only show users within 500 meters
          if (distance <= 500) { 
            tempList.add({
              "phone": key, 
              "distance": distance.toStringAsFixed(0)
            });
          }
        }
      });
      if (mounted) setState(() => nearbyUsers = tempList);
    });
  }

  // --- REQUEST LOGIC ---

  // --- UPDATED REQUEST LOGIC ---

  void listenForIncomingRequests() {
    // 1. Listen for requests sent TO ME (Receiver side)
    dbRef.child("rideRequests").orderByChild("to").equalTo(myPhone).onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data["status"] == "pending") {
        _showRequestDialog(event.snapshot.key!, data["from"]);
      }
    });

    // 2. Listen for status changes on requests I SENT (Sender side)
    dbRef.child("rideRequests").orderByChild("from").equalTo(myPhone).onChildChanged.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data["status"] == "accepted" && data["groupId"] != null && !hasNavigatedToGroup) {
        _navigateToGroup(data["groupId"]);
      }
    });

    // 3. Optional: Listen for when a request I RECEIVED is accepted (In case of multiple requests)
    dbRef.child("rideRequests").orderByChild("to").equalTo(myPhone).onChildChanged.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data["status"] == "accepted" && data["groupId"] != null && !hasNavigatedToGroup) {
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
        content: Text("User $senderPhone wants to share a ride."),
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
              // Close dialog first
              Navigator.pop(context);
              
              // 1. Generate the Group ID
              String groupId = dbRef.child("rideGroups").push().key!;
              
              // 2. Create the Group
              await dbRef.child("rideGroups/$groupId").set({
                "members": { myPhone!: true, senderPhone: true },
                "destination": widget.destinationId,
                "status": "waiting", // For the sync logic we built earlier
                "createdAt": ServerValue.timestamp,
              });

              // 3. Update request status. 
              // This triggers 'onChildChanged' for the SENDER and the listener above for the RECEIVER.
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

  Future<void> _createRideGroup(String otherPhone, String requestId) async {
    String groupId = dbRef.child("rideGroups").push().key!;
    await dbRef.child("rideGroups/$groupId").set({
      "members": { myPhone!: true, otherPhone: true },
      "destination": widget.destinationId,
      "createdAt": ServerValue.timestamp,
    });
    await dbRef.child("rideRequests/$requestId").update({"groupId": groupId});
  }

  Future<void> sendRideRequest(String receiverPhone) async {
    String requestId = dbRef.child("rideRequests").push().key!;
    await dbRef.child("rideRequests/$requestId").set({
      "from": myPhone,
      "to": receiverPhone,
      "status": "pending",
      "createdAt": ServerValue.timestamp,
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + 
              cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  @override
  void dispose() {
    positionStream?.cancel();
    if (myPhone != null) {
      dbRef.child("grouping/$myPhone").update({"isActive": false});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Commuters"), backgroundColor: Colors.indigo),
      body: nearbyUsers.isEmpty 
        ? const Center(child: Text("Searching for people nearby..."))
        : ListView.builder(
            itemCount: nearbyUsers.length,
            itemBuilder: (context, index) {
              final user = nearbyUsers[index];
              return ListTile(
                title: Text("Commuter: ${user['phone']}"),
                subtitle: Text("${user['distance']}m away"),
                trailing: ElevatedButton(
                  onPressed: () => sendRideRequest(user['phone']),
                  child: const Text("Request"),
                ),
              );
            },
          ),
    );
  }
}