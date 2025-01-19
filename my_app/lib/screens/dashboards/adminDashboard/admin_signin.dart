import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/adminDashboard/admin_base_page.dart';
import 'package:my_app/screens/dashboards/adminDashboard/admin_dashboard.dart';
import 'package:my_app/services/auth_service.dart';

final storage = FlutterSecureStorage();

class AdminSignInScreen extends StatefulWidget {
  final Future<void> Function() onSignOut;

    AdminSignInScreen({required this.onSignOut});
  @override
  _AdminSignInScreenState createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _apiService = AuthService();

  @override
  void initState() {
    super.initState();
  }

    Future<void> _handleVerification() async {
    try {
      final response = await _apiService.adminSignIn(_usernameController.text, _passwordController.text);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        String jwtToken = body['jwtToken'];
        String userId = body['userId'];
        String firebaseCustomToken = body['firebaseCustomToken'];
        String role = "admin";

        if (response.statusCode == 200) {
            // Save role, JWT and userId in secure storage when signed in
            await storage.write(key: "role", value: role);
            await storage.write(key: "jwtToken", value: jwtToken);
            await storage.write(key: "userId", value: userId);

            // Authenticate with Firebase using the custom token
            await FirebaseAuth.instance
                .signInWithCustomToken(firebaseCustomToken);
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              print("Authenticated user: ${user.uid}");
            } else {
              print("Authentication failed.");
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => AdminBasePage(
                  onSignOut: widget.onSignOut,
                  adminId: userId,
                ),
              ),
              (route) => false,
            );
        }
      } else {
        showErrorDialog('Invalid Credentials. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog('An error occurred. Please try again.');
    }
  }

    void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE4B5),
        title: Text(
          "Admin Sign In",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Email/Phone Number",
                    labelStyle: TextStyle(color: Color(0xFFFAAF84)),
                    filled: true,
                    fillColor: Color(0xFFFFF8EE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Color(0xFFFAAF84)),
                    filled: true,
                    fillColor: Color(0xFFFFF8EE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84), width: 2),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFAAF84),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _handleVerification,
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
