import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool alreadyRegistered = false;

  /// 🔹 Save phone locally
  Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', phone);
  }

  /// 🔹 Get saved phone
  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone');
  }

  /// 🔎 Check Firestore
  Future<DocumentSnapshot> getUser(String phone) {
    return FirebaseFirestore.instance.collection('users').doc(phone).get();
  }

  /// 🔥 AUTO CHECK WHEN APP OPENS
  Future<void> checkExistingUser() async {
    final savedPhone = await getSavedPhone();

    if (savedPhone == null) return;

    phoneController.text = savedPhone;

    final doc = await getUser(savedPhone);

    if (doc.exists) {
      setState(() => alreadyRegistered = true);

      final data = doc.data() as Map<String, dynamic>;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Already Registered"),
            content: Text(
              "You are already registered.\n\n"
              "Name: ${data['name']}\n"
              "Phone: ${data['phone']}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
    }
  }

  /// 🚀 Register new user
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final phone = phoneController.text.trim();

    try {
      final doc = await getUser(phone);

      /// 🚨 If already exists
      if (doc.exists) {
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User already registered")),
        );
        return;
      }

      /// ✅ Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(phone).set({
        'name': nameController.text.trim(),
        'gender': genderController.text.trim(),
        'phone': phone,
        'age': int.parse(ageController.text.trim()),
        'createdAt': Timestamp.now(),
      });

      /// ✅ Save phone locally
      await savePhone(phone);

      setState(() {
        isLoading = false;
        alreadyRegistered = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    checkExistingUser(); // 🔥 Auto check
  }

  @override
  void dispose() {
    nameController.dispose();
    genderController.dispose();
    phoneController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: alreadyRegistered
            ? const Center(
                child: Text(
                  "✅ You are already registered",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (v) => v!.isEmpty ? "Enter name" : null,
                    ),
                    TextFormField(
                      controller: genderController,
                      decoration: const InputDecoration(labelText: "Gender"),
                      validator: (v) => v!.isEmpty ? "Enter gender" : null,
                    ),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: "Phone Number"),
                      validator: (v) =>
                          v!.length != 10 ? "Enter valid phone" : null,
                    ),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age"),
                      validator: (v) => v!.isEmpty ? "Enter age" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : registerUser,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Signup"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}