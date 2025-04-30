import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:water_supply/service/api_service.dart';
import 'components/Customer/customer_home_screen.dart';
import 'components/Delivery/delivery_home_screen.dart';
import 'components/Distributer/distributor_home_screen.dart';
import 'components/admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () async {
      await _checkUserStatus();
    });
  }

  Future<void> _checkUserStatus() async {
    if (!mounted) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final storedAccountId = prefs.getString('accountId');
      final storedPassword = prefs.getString('password');
      final storedRole = prefs.getString('role');

      if (!isLoggedIn ||
          storedAccountId == null ||
          storedPassword == null ||
          storedRole == null) {
        _navigateToLogin();
        return;
      }

      final response = await _apiService.login(
        storedAccountId,
        storedPassword,
        storedRole,
      );

      if (response['success'] == true && response['user'] != null) {
        await _handleNavigation(storedRole, response['user']);
      } else {
        await prefs.clear();
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('Error during auto-login: $e');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _navigateToLogin();
    } finally {
      if (mounted) {}
    }
  }

  Future<void> _handleNavigation(
    String role,
    Map<String, dynamic> userData,
  ) async {
    switch (role.toLowerCase()) {
      case 'customer':
        _navigateTo(CustomerHomeScreen());
        break;
      case 'distributor':
        _navigateTo(
          DistributorHomeScreen(
            distributorName: userData['name'],
            distributorID: userData['accountId'].toString(),
          ),
        );
        break;
      case 'delivery':
        _navigateTo(DeliveryHomeScreen());
        break;
      case 'admin':
        _navigateTo(AdminHomeScreen());
        break;
      default:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('lib/assets/logo.png', height: 450),
              SizedBox(height: 20),
              SpinKitThreeBounce(color: Colors.white, size: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}
