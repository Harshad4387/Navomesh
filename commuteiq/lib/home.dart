import 'package:commuteiq/Widget/app_drawer.dart';
import 'package:flutter/material.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CommuteIq"),
        centerTitle: true,
      ),

      // ✅ Call reusable drawer
      drawer: const AppDrawer(),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.traffic, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "Welcome to UrbanFlow 🚦",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Smart commute planning for smarter cities.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}