import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/screens/components/Customer/customer_home_screen.dart';
import 'package:water_supply/screens/components/Delivery/delivery_home_screen.dart';
import 'package:water_supply/screens/components/Distributer/distributor_home_screen.dart';
import 'package:water_supply/screens/components/admin/admin_home_screen.dart';
import 'package:water_supply/screens/components/admin/n_admin_homescreen.dart';
import 'package:water_supply/screens/signup_page.dart';
import 'package:water_supply/service/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final TextEditingController roleController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? selectedRole;

  // First, create a mapping between display names and API values
  final Map<String, String> roleMapping = {
    'Customer': 'customer',
    'Distributor': 'distributor',
    'Delivery': 'delivery',
    'Admin': 'admin',
    'Super Admin': 'super_admin',
  };

  // Replace the existing roles list with display names
  final List<String> roles = [
    'Customer',
    'Distributor',
    'Delivery',
    'Admin',
    'Super Admin'
  ];

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleLogin() async {
    if (idController.text.isEmpty ||
        roleController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        idController.text.trim(),
        passwordController.text,
        roleController.text.trim(),
      );

      if (response['success'] != true) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Account Not Approved'),
              content: Text(
                'Your account is pending approval from the administrator. Please try again later.',
              ),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        setState(() => _isLoading = false);
        return;
      }

      // Store the token and user data
      final String? token = response['token'];
      final Map<String, dynamic>? userData = response['user'];

      if (token == null || userData == null) {
        _showErrorDialog('Invalid response from server');
        return;
      }

      // Save login credentials and user data
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('accountId', idController.text.trim());
      await prefs.setString('password', passwordController.text);
      await prefs.setString('role', roleController.text.trim());
      await prefs.setString('token', token);
      await prefs.setString('userData', json.encode(userData));
      await prefs.setBool('isLoggedIn', true);
      // Add last login timestamp
      await prefs.setInt(
        'lastLoginTime',
        DateTime.now().millisecondsSinceEpoch,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login successful')));

      // Navigate based on role
      switch (userData['role']) {
        case 'distributor':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DistributorHomeScreen(
                    distributorName: userData['name'],
                    distributorID: userData['accountId'].toString(),
                  ),
            ),
            (route) => false,
          );
          break;
        case 'customer':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
            (route) => false,
          );
          break;
        case 'delivery':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DeliveryHomeScreen()),
            (route) => false,
          );
          break;
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AsAdminHomeScreen()),
            (route) => false,
          );
        case 'super_admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()),
            (route) => false,
          );
          break;
        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid user role')));
      }
    } catch (e) {
      String errorMessage = 'Something went wrong. Please try again.';

      if (e.toString().contains('Connection refused')) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timed out. Please try again.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // Logo or Brand Icon
                Icon(
                  Icons.water_drop,
                  size: 80,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 20),
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login to your account",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                // Account ID Field
                _buildTextField(
                  controller: idController,
                  label: "Account ID",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                // Role Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedRole != null 
                        ? roles.firstWhere(
                            (r) => roleMapping[r] == selectedRole,
                            orElse: () => roles[0]
                          )
                        : null,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue.shade700),
                    decoration: InputDecoration(
                      labelText: "Role",
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(Icons.work_outline, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                    ),
                    items: roles.map((String displayRole) {
                      return DropdownMenuItem<String>(
                        value: displayRole,
                        child: Text(
                          displayRole,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedRole = roleMapping[newValue];
                        roleController.text = roleMapping[newValue] ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Password Field
                _buildTextField(
                  controller: passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                // Sign Up Link
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                      (route) => false,
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blue.shade700,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

// Add this extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
