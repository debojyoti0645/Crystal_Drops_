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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue.shade800,
          title: const Text(
            'Manage Zones',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.orange.shade400,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.view_list,
                      color: Colors.orange.shade300,
                    ),
                    text: 'View Zones',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.edit_location_alt,
                      color: Colors.blue.shade300,
                    ),
                    text: 'Edit Zones',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.add_location_alt,
                      color: Colors.green.shade300,
                    ),
                    text: 'Create Zone',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
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
