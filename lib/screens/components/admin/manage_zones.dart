import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service/api_service.dart';
import 'admin_tabs/zone tabs/create_zones.dart';
import 'admin_tabs/zone tabs/edit_zone.dart';
import 'admin_tabs/zone tabs/view_zones.dart';

class ManageZonesScreen extends StatefulWidget {
  const ManageZonesScreen({Key? key}) : super(key: key);

  @override
  State<ManageZonesScreen> createState() => _ManageZonesScreenState();
}

class _ManageZonesScreenState extends State<ManageZonesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAuth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _apiService.setAuthToken(token);
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Zones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.amber,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.view_list),
              text: 'View Zones',
            ),
            Tab(
              icon: Icon(Icons.edit_location_alt),
              text: 'Edit Zones',
            ),
            Tab(
              icon: Icon(Icons.add_location_alt),
              text: 'Create Zone',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade50],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            ViewZonesTab(),
            EditZonesTab(),
            CreateZoneTab(),
          ],
        ),
      ),
    );
  }
}
