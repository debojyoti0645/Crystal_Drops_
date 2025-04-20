import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/screens/login_screen.dart';

class DistAppDrawer extends StatefulWidget {
  const DistAppDrawer({super.key});

  @override
  State<DistAppDrawer> createState() => _DistAppDrawerState();
}

class _DistAppDrawerState extends State<DistAppDrawer> {
  final storage = FlutterSecureStorage();
  String userName = "Welcome!";
  String userRole = "Loading...";
  String accountId = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString != null) {
        final userData = json.decode(userDataString);
        setState(() {
          userName = userData['name'] ?? "Guest";
          userRole = userData['role'] ?? "User";
          accountId = userData['accountId']?.toString() ?? "";
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = "Guest";
        userRole = "User";
        accountId = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      userName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userRole.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (accountId.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 16, color: Colors.white70),
                          SizedBox(width: 8),
                          Text(
                            "ID: $accountId",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.home, color: Color(0xFF007BFF)),
                    title: Text(
                      "Home",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  //prfile
                  ListTile(
                    leading: Icon(Icons.person, color: Color(0xFF007BFF)),
                    title: Text(
                      "Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      // Navigate to Profile Page
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.shopping_cart,
                      color: Color(0xFF007BFF),
                    ),
                    title: Text(
                      "Orders",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      // Navigate to Orders Page
                      Navigator.pushNamed(context, '/dist_orders');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.payment, color: Color(0xFF007BFF)),
                    title: Text(
                      "Payment History",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      // Navigate to Payment History Page
                      Navigator.pushNamed(context, '/dist_payment');
                    },
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () async {
                      // Show Logout Confirmation Dialog
                      bool confirmLogout = await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text("Logout"),
                              content: Text(
                                "Are you sure you want to log out?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Logout"),
                                ),
                              ],
                            ),
                      );

                      if (confirmLogout == true) {
                        await storage.deleteAll();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
