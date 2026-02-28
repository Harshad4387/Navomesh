// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class RideGroupScreen extends StatefulWidget {
//   final String groupId;

//   const RideGroupScreen({super.key, required this.groupId});

//   @override
//   State<RideGroupScreen> createState() => _RideGroupScreenState();
// }

// class _RideGroupScreenState extends State<RideGroupScreen> {
//   final dbRef = FirebaseDatabase.instance.ref();
//   bool dialogShown = false; // Prevents the dialog from popping up multiple times

//   // This function updates the DB so EVERYONE sees the booking start
//   void syncBookingStatus() async {
//     await dbRef.child("rideGroups/${widget.groupId}").update({
//       "status": "booking",
//     });

//     // Simulate backend processing for 3 seconds, then set to ready
//     Future.delayed(const Duration(seconds: 3), () async {
//       await dbRef.child("rideGroups/${widget.groupId}").update({
//         "status": "ready",
//       });
//     });
//   }

//   void _showSyncDialog() {
//     if (dialogShown) return;
//     dialogShown = true;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: const [
//             CircularProgressIndicator(),
//             SizedBox(height: 20),
//             Text("Booking shared ride for the group...",
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primary = Theme.of(context).colorScheme.primary;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Ride Group"), backgroundColor: primary),
//       body: StreamBuilder(
//         stream: dbRef.child("rideGroups/${widget.groupId}").onValue,
//         builder: (context, snapshot) {
//           if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final groupData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
//           final members = Map<String, dynamic>.from(groupData['members'] ?? {});
//           final String status = groupData['status'] ?? "waiting";

//           // SYNC LOGIC: If 3 members joined and no one started booking yet
//           if (members.length >= 3 && status == "waiting") {
//             syncBookingStatus();
//           }

//           // UI SYNC: If status is 'booking', show dialog on ALL phones
//           if (status == "booking") {
//             WidgetsBinding.instance.addPostFrameCallback((_) => _showSyncDialog());
//           }

//           // UI SYNC: If status is 'ready', close dialog on ALL phones
//           if (status == "ready" && dialogShown) {
//             Navigator.of(context, rootNavigator: true).pop();
//             dialogShown = false; 
//           }

//           return Column(
//             children: [
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.all(16),
//                   children: [
//                     Text("Group Members (${members.length}/3)", 
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 15),
//                     ...members.keys.map((memberId) => Card(
//                       child: ListTile(
//                         leading: const CircleAvatar(child: Icon(Icons.person)),
//                         title: Text("User: $memberId"),
//                       ),
//                     )).toList(),
//                   ],
//                 ),
//               ),
              
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: status == "ready" ? Colors.green : primary,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   onPressed: status == "ready" ? () {
//                     // Navigate to payment
//                   } : null, // Disable until group is ready
//                   child: Text(
//                     status == "ready" ? "Continue to Payment" : "Waiting for Group...",
//                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

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
  bool dialogShown = false; 

  void syncBookingStatus() async {
    await dbRef.child("rideGroups/${widget.groupId}").update({
      "status": "booking",
    });

    // Simulate backend "Nash-Optimization" processing
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 25),
            Text("Optimizing Fare...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            Text("Calculating the best shared route for your group.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Group waiting room", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: dbRef.child("rideGroups/${widget.groupId}").onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final members = Map<String, dynamic>.from(groupData['members'] ?? {});
          final String status = groupData['status'] ?? "waiting";

          // SYNC LOGIC
          if (members.length >= 3 && status == "waiting") {
            syncBookingStatus();
          }

          if (status == "booking") {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showSyncDialog());
          }

          if (status == "ready" && dialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
            dialogShown = false; 
          }

          return Column(
            children: [
              _buildProgressHeader(members.length),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text("YOUR CONVOY CREW", 
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 15),
                    ...members.keys.map((memberId) => _buildMemberCard(memberId)).toList(),
                    const SizedBox(height: 25),
                    if (status == "ready") _buildFareBreakdown(),
                  ],
                ),
              ),
              _buildBottomAction(status),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(int count) {
    double progress = count / 3;
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Matching Status", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
              Text("$count / 3 Members", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(String phone) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.indigo),
        ),
        title: Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text("Ready to depart", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ),
    );
  }

  Widget _buildFareBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Individual Fare", style: TextStyle(color: Colors.black54)),
              Text("₹85.00", style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Optimized Group Fare", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("₹28.00", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(String status) {
    bool isReady = status == "ready";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? Colors.green : Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            onPressed: isReady ? () {
              // Trigger Payment Flow
            } : null,
            child: Text(
              isReady ? "PROCEED TO PAYMENT" : "WAITING FOR 3RD MEMBER...",
              style: TextStyle(color: isReady ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}