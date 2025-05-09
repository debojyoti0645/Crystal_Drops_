import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:water_supply/screens/components/admin/admin_app_drawer%20copy.dart';
import 'package:water_supply/screens/components/admin/admin_app_drawer.dart';
import 'package:water_supply/screens/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'SUPER ADMIN DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/notification'),
            icon: Icon(Icons.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      drawer: const SAdminAppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade50],
          ),
        ),
        child: Column(
          children: [
            // Dashboard Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      context,
                      'Manage Users',
                      Icons.people,
                      '/manage-users',
                      Colors.orange,
                    ),
                    _buildDashboardCard(
                      context,
                      'Manage Connections',
                      Icons.emoji_people_outlined,
                      '/manage-connections',
                      Colors.red,
                    ),
                    _buildDashboardCard(
                      context,
                      'Manage Products',
                      Icons.inventory,
                      '/manage-products',
                      Colors.green,
                    ),
                    _buildDashboardCard(
                      context,
                      'Manage Admin',
                      Icons.admin_panel_settings,
                      '/manage-admin',
                      Colors.teal,
                    ),
                    _buildDashboardCard(
                      context,
                      'Manage Orders',
                      Icons.shopping_cart,
                      '/manage-orders',
                      Colors.purple,
                    ),
                    _buildDashboardCard(
                      context,
                      'Manage Zones',
                      Icons.location_city,
                      '/manage-zones',
                      Colors.blue,
                    ),

                    _buildDashboardCard(
                      context,
                      'Delivery',
                      Icons.car_rental,
                      '/delivery',
                      Colors.cyan,
                    ),

                    _buildDashboardCard(
                      context,
                      'Transactions',
                      Icons.money_rounded,
                      '/transactions',
                      const Color.fromARGB(255, 152, 202, 76),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      await storage.deleteAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }
}
