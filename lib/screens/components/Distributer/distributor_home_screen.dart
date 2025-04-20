import 'package:flutter/material.dart';
import 'package:water_supply/screens/components/Distributer/dist_app_drawer.dart';
import 'package:water_supply/screens/components/Distributer/dist_order_summary.dart';
import 'package:water_supply/screens/components/Distributer/dist_payment_history.dart';
import 'package:water_supply/screens/components/Distributer/place_order_screen.dart';
import 'dart:io';

import 'package:water_supply/screens/profile_screen.dart';

class DistributorHomeScreen extends StatelessWidget {
  final String distributorName;
  final String distributorID;

  const DistributorHomeScreen({
    super.key,
    required this.distributorName,
    required this.distributorID,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        exit(0);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'Distributor Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        drawer: const DistAppDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle tap on the card
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 8,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        width: double.infinity, // Make container fill width
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ), // Reduce vertical padding
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          // Change to Row for horizontal layout
                          children: [
                            CircleAvatar(
                              radius: 30, // Reduce avatar size
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 30, // Reduce icon size
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ), // Add spacing between avatar and text
                            Expanded(
                              // Allow text to take remaining space
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start, // Align text to start
                                mainAxisSize:
                                    MainAxisSize.min, // Minimize column height
                                children: [
                                  Text(
                                    distributorName,
                                    style: const TextStyle(
                                      fontSize: 20, // Slightly smaller font
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Distributor',
                                    style: TextStyle(
                                      fontSize: 16, // Smaller font for role
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: $distributorID',
                                    style: TextStyle(
                                      fontSize: 16, // Smaller font for ID
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildFeatureCard(
                        context,
                        'Place Order',
                        Icons.shopping_cart,
                        Colors.blue.shade700,
                        const PlaceOrderScreen(),
                      ),
                      _buildFeatureCard(
                        context,
                        'Orders Summary',
                        Icons.list_alt,
                        Colors.orange.shade700,
                        const OrderSummary(),
                      ),
                      _buildFeatureCard(
                        context,
                        'Payment History',
                        Icons.payment,
                        Colors.green.shade700,
                        const PaymentHistory(),
                      ),
                      _buildFeatureCard(
                        context,
                        'Analytics',
                        Icons.analytics,
                        Colors.purple.shade700,
                        const PaymentHistory(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
