import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final genderController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  bool isLoading = false;

  /// 🔎 Check user by phone (Doc ID)
  Future<DocumentSnapshot> getUser(String phone) {
    return FirebaseFirestore.instance.collection('users').doc(phone).get();
  }

  /// 🚀 Register or Show Existing User
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final phone = phoneController.text.trim();

    try {
      final doc = await getUser(phone);

      /// 🚨 USER EXISTS
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() => isLoading = false);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Already Registered"),
            content: Text(
              "You are already registered.\n\n"
              "Name: ${data['name']}\n"
              "Gender: ${data['gender']}\n"
              "Phone: ${data['phone']}\n"
              "Age: ${data['age']}",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );

        return;
      }

      /// ✅ SAVE NEW USER
      await FirebaseFirestore.instance.collection('users').doc(phone).set({
        'name': nameController.text.trim(),
        'gender': genderController.text.trim(),
        'phone': phone,
        'age': int.parse(ageController.text.trim()),
        'createdAt': Timestamp.now(),
      });

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Registered Successfully")),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),

              /// GENDER
              TextFormField(
                controller: genderController,
                decoration: const InputDecoration(labelText: "Gender"),
                validator: (v) => v!.isEmpty ? "Enter gender" : null,
              ),

              /// PHONE
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (v) =>
                    v!.length != 10 ? "Enter valid phone" : null,
              ),

              /// AGE
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
                validator: (v) => v!.isEmpty ? "Enter age" : null,
              ),

              const SizedBox(height: 20),

              /// SIGNUP BUTTON
              ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Signup"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}