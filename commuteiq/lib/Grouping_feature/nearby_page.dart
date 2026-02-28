// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:shared_preferences/shared_preferences.dart'; 
// import 'ride_grouping_screen.dart'; 

// class NearbyUsersPage extends StatefulWidget {
//   final String destinationId;
//   final String destinationName;
//   final double destLat;
//   final double destLng;

//   const NearbyUsersPage({
//     super.key,
//     required this.destinationId,
//     required this.destinationName,
//     required this.destLat,
//     required this.destLng,
//   });

//   @override
//   State<NearbyUsersPage> createState() => _NearbyUsersPageState();
// }

// class _NearbyUsersPageState extends State<NearbyUsersPage> {
//   final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

//   String? myPhone; 
//   List<Map<String, dynamic>> activeUsers = [];
//   bool hasNavigatedToGroup = false;
//   StreamSubscription? _usersSubscription;
//   StreamSubscription? _requestAddedSubscription;
//   StreamSubscription? _requestChangedSubscription;

//   @override
//   void initState() {
//     super.initState();
//     initUser();
//   }

//   Future<void> initUser() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     myPhone = prefs.getString('phone'); 

//     if (myPhone == null || myPhone!.isEmpty) {
//        debugPrint("Error: No phone number found in shared preferences.");
//        return;
//     }

//     // 1. Mark yourself as Active immediately so others can see you
//     await dbRef.child("grouping/$myPhone").set({
//       "phone": myPhone,
//       "destinationId": widget.destinationId,
//       "isActive": true,
//       "lastSeen": ServerValue.timestamp,
//     });

//     // Automatically set to offline if the user kills the app
//     dbRef.child("grouping/$myPhone/isActive").onDisconnect().set(false);

//     // 2. Start real-time listeners
//     listenForActiveUsers();
//     listenForIncomingRequests();
//   }

//   // --- UPDATED: IMPROVED REAL-TIME LISTENER ---
//   void listenForActiveUsers() {
//     // Listen to the entire grouping node
//     _usersSubscription = dbRef.child("grouping").onValue.listen((event) {
//       final data = event.snapshot.value as Map?;
//       if (data == null) return;

//       List<Map<String, dynamic>> tempList = [];
      
//       data.forEach((key, value) {
//         // Condition:
//         // 1. Not me
//         // 2. isActive is true
//         // 3. Same destinationId
//         if (key != myPhone) {
//           final user = Map<String, dynamic>.from(value as Map);
//           if (user["isActive"] == true && user["destinationId"] == widget.destinationId) {
//             tempList.add({
//               "phone": key,
//               "status": "Online",
//             });
//           }
//         }
//       });

//       if (mounted) {
//         setState(() {
//           activeUsers = tempList;
//         });
//       }
//     });
//   }

//   void listenForIncomingRequests() {
//     _requestAddedSubscription = dbRef.child("rideRequests").orderByChild("to").equalTo(myPhone).onChildAdded.listen((event) {
//       final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//       if (data["status"] == "pending") {
//         _showRequestDialog(event.snapshot.key!, data["from"]);
//       }
//     });

//     _requestChangedSubscription = dbRef.child("rideRequests").onChildChanged.listen((event) {
//       final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//       bool involvesMe = data["from"] == myPhone || data["to"] == myPhone;
      
//       if (involvesMe && data["status"] == "accepted" && !hasNavigatedToGroup) {
//         _navigateToGroup(data["groupId"]);
//       }
//     });
//   }

//   void _navigateToGroup(String groupId) {
//     hasNavigatedToGroup = true;
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => RideGroupScreen(groupId: groupId)),
//     );
//   }

//   void _showRequestDialog(String requestId, String senderPhone) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Ride Request"),
//         content: Text("User $senderPhone wants to join your ride!"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               dbRef.child("rideRequests/$requestId").update({"status": "rejected"});
//               Navigator.pop(context);
//             },
//             child: const Text("DECLINE"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               String groupId = dbRef.child("rideGroups").push().key!;
              
//               await dbRef.child("rideGroups/$groupId").set({
//                 "members": { myPhone!: true, senderPhone: true },
//                 "destination": widget.destinationId,
//                 "createdAt": ServerValue.timestamp,
//               });

//               await dbRef.child("rideRequests/$requestId").update({
//                 "status": "accepted",
//                 "groupId": groupId,
//               });
//             },
//             child: const Text("ACCEPT"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> sendRideRequest(String receiverPhone) async {
//     String requestId = dbRef.child("rideRequests").push().key!;
//     await dbRef.child("rideRequests/$requestId").set({
//       "from": myPhone,
//       "to": receiverPhone,
//       "status": "pending",
//       "createdAt": ServerValue.timestamp,
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Request sent to $receiverPhone")),
//     );
//   }

//   @override
//   void dispose() {
//     // 1. Mark myself as inactive when leaving the page
//     if (myPhone != null) {
//       dbRef.child("grouping/$myPhone").update({"isActive": false});
//     }
//     // 2. Cancel all subscriptions to prevent memory leaks
//     _usersSubscription?.cancel();
//     _requestAddedSubscription?.cancel();
//     _requestChangedSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Going to ${widget.destinationName}"),
//         backgroundColor: Colors.indigo,
//         elevation: 0,
//       ),
//       body: activeUsers.isEmpty 
//         ? Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const CircularProgressIndicator(color: Colors.indigo),
//                 const SizedBox(height: 20),
//                 const Text("Finding commuters near you...", style: TextStyle(fontSize: 16, color: Colors.grey)),
//                 Text("Destination: ${widget.destinationId}", style: const TextStyle(fontSize: 12, color: Colors.black38)),
//               ],
//             ),
//           )
//         : ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: activeUsers.length,
//             itemBuilder: (context, index) {
//               final user = activeUsers[index];
//               return Card(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                 elevation: 3,
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.indigo,
//                     child: Icon(Icons.person, color: Colors.white),
//                   ),
//                   title: Text(user['phone'], style: const TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: const Row(
//                     children: [
//                       Icon(Icons.circle, color: Colors.green, size: 10),
//                       SizedBox(width: 5),
//                       Text("Active Now", style: TextStyle(color: Colors.green)),
//                     ],
//                   ),
//                   trailing: ElevatedButton(
//                     onPressed: () => sendRideRequest(user['phone']),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
//                     child: const Text("Request"),
//                   ),
//                 ),
//               );
//             },
//           ),
//     );
//   }
// }

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
  String? activeGroupId; 
  bool isAccepted = false;
  
  bool showMockUser = true; 
  final String mockPhoneNumber = "1282783643";

  @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    myPhone = prefs.getString('phone'); 

    if (myPhone == null || myPhone!.isEmpty) return;

    // 1. Mark yourself as Active
    await dbRef.child("grouping/$myPhone").update({
      "phone": myPhone,
      "destinationId": widget.destinationId,
      "isActive": true,
      "lastSeen": ServerValue.timestamp,
    });

    dbRef.child("grouping/$myPhone/isActive").onDisconnect().set(false);

    listenForActiveUsers();
    listenForIncomingRequests();
  }

  void listenForActiveUsers() {
    dbRef.child("grouping").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      List<Map<String, dynamic>> tempList = [];

      if (showMockUser) {
        tempList.add({
          "phone": mockPhoneNumber,
          "status": "Online",
          "isMock": true,
        });
      }

      if (data != null) {
        data.forEach((key, value) {
          if (key == myPhone) return;
          final user = Map<String, dynamic>.from(value as Map);
          if (user["isActive"] == true && user["destinationId"] == widget.destinationId) {
            if (key != mockPhoneNumber) {
              tempList.add({
                "phone": key,
                "status": "Online",
                "isMock": false,
              });
            }
          }
        });
      }

      if (mounted) setState(() => activeUsers = tempList);
    });
  }

  void listenForIncomingRequests() {
    dbRef.child("rideRequests").orderByChild("to").equalTo(myPhone).onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data["status"] == "pending") {
        _showRequestDialog(event.snapshot.key!, data["from"]);
      }
    });

    dbRef.child("rideRequests").onChildChanged.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      bool involvesMe = data["from"] == myPhone || data["to"] == myPhone;
      
      if (involvesMe && data["status"] == "accepted") {
        if (mounted) {
          setState(() {
            activeGroupId = data["groupId"];
            isAccepted = true;
          });
        }
      }
    });
  }

  void _showRequestDialog(String requestId, String senderPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Ride Request"),
        content: Text("User $senderPhone is ready to go!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("DECLINE")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              String groupId = dbRef.child("rideGroups").push().key!;
              
              await dbRef.child("rideGroups/$groupId").set({
                "members": { myPhone!: true, senderPhone: true },
                "destination": widget.destinationId,
                "status": "waiting",
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

  // --- UPDATED SIMULATION LOGIC ---
  Future<void> sendRideRequest(String receiverPhone, bool isMock) async {
    String requestId = dbRef.child("rideRequests").push().key!;
    
    await dbRef.child("rideRequests/$requestId").set({
      "from": myPhone,
      "to": receiverPhone,
      "status": "pending",
      "createdAt": ServerValue.timestamp,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sending request to nearby commuters...")),
    );

    if (isMock) {
      // Wait 2 seconds to simulate a real response delay
      Timer(const Duration(seconds: 2), () async {
        String mockGroupId = "MOCK_GROUP_${DateTime.now().millisecondsSinceEpoch}";
        
        // 1. Create the Group and add both members immediately
        await dbRef.child("rideGroups/$mockGroupId").set({
          "members": { 
            myPhone!: true, 
            mockPhoneNumber: true 
          },
          "destination": widget.destinationId,
          "status": "waiting",
          "createdAt": ServerValue.timestamp,
        });

        // 2. Update status to 'accepted' to trigger the JOIN RIDE UI
        await dbRef.child("rideRequests/$requestId").update({
          "status": "accepted",
          "groupId": mockGroupId,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(widget.destinationName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: activeUsers.isEmpty 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final user = activeUsers[index];
              bool isMock = user['isMock'] ?? false;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMock ? Colors.orange.withOpacity(0.2) : Colors.indigo.withOpacity(0.2),
                    child: Icon(Icons.person, color: isMock ? Colors.orange : Colors.indigo),
                  ),
                  title: Text(user['phone'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isMock ? "Simulated Commuter" : "Active Now", 
                    style: TextStyle(color: isMock ? Colors.orange : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  trailing: ElevatedButton(
                    onPressed: isAccepted ? null : () => sendRideRequest(user['phone'], isMock),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAccepted ? Colors.grey : Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: const Text("Request"),
                  ),
                ),
              );
            },
          ),
      // --- DYNAMIC RIDE ACTION BAR ---
      bottomNavigationBar: isAccepted ? Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Potential Match!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("User 1282... has joined the ride", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RideGroupScreen(groupId: activeGroupId!)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text("JOIN RIDE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }
}