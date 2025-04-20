import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:water_supply/screens/components/Customer/cust_app_drawer.dart';
import 'package:water_supply/service/api_service.dart';

import 'home/home_banner.dart';
import 'home/product_grid.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ApiService _apiService = ApiService();
  HomeBanner _cachedBanner = HomeBanner();
  ProductGrid _cachedGrid = ProductGrid();
  UserProfile? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final response = await _apiService.getUserProfile();
    if (response['success'] && response['user'] != null) {
      setState(() {
        currentUser = UserProfile.fromJson(response['user']);
      });
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await _loadUserProfile();
      setState(() {
        _cachedBanner = HomeBanner();
        _cachedGrid = ProductGrid();
      });
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Crystal Drops",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed('/cart');
              },
            ),
          ],
        ),
        drawer: CustAppDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Color(0xFF007BFF),
            child: RepaintBoundary(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _cachedBanner,
                          SizedBox(height: 20),
                          Divider(color: Colors.grey.shade400, thickness: 1),
                          SizedBox(height: 20),
                          Text(
                            "Choose Your Water Bottle",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),
                          Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: _cachedGrid,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "© 2025 Crystal Drops. All Rights Reserved.",
                          style: TextStyle(
                            fontSize: 16,
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
        ),
      ),
    );
  }
}
