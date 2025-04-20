import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/screens/components/Customer/subscription/subscribed_screen.dart';
import 'package:water_supply/screens/components/Customer/subscription/subscription_page.dart';
import 'package:water_supply/service/api_service.dart';

class CustMngConnection extends StatefulWidget {
  const CustMngConnection({super.key});

  @override
  State<CustMngConnection> createState() => _CustMngConnectionState();
}

class _CustMngConnectionState extends State<CustMngConnection> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _userId;
  Map<String, dynamic>? _connectionDetails;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Initialize API service and load user data
      await _apiService.initializeAuthToken();
      await _loadUserData();
      
      if (_userId != null) {
        final result = await _apiService.getUserConnectionDetails(_userId!);
        
        setState(() {
          _connectionDetails = result['connectionDetails'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');
      
      if (userDataString != null) {
        final Map<String, dynamic> userData = json.decode(userDataString);
        setState(() {
          _userId = userData['accountId'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If connection details exist, show SubscribedScreen, otherwise show SubscribePage
    if (_connectionDetails != null) {
      return SubscribedScreen(
        connectionDetails: _connectionDetails!,
      );
    } else {
      return const SubscribePage();
    }
  }
}