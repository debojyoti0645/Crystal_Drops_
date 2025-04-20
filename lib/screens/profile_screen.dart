import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/service/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _apiService.initializeAuthToken();
      final response = await _apiService.getUserProfile();

      if (response['success']) {
        setState(() {
          _userProfile = response['user'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Profile...',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: Colors.blue.shade800,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 240,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade900,
                                  Colors.blue.shade800,
                                  Colors.blue.shade700,
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Background Pattern
                                Positioned.fill(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ).createShader(bounds),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://www.transparenttextures.com/patterns/cubes.png',
                                          ),
                                          repeat: ImageRepeat.repeat,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Profile Content
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 48),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            _userProfile?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _userProfile?['name'] ?? 'User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _userProfile?['role']?.toUpperCase() ?? 'USER',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSection(
                                  'Account Information',
                                  [
                                    _buildInfoTile(
                                      'Account ID',
                                      _userProfile?['accountId'] ?? 'N/A',
                                      Icons.badge,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Role',
                                      _userProfile?['role']?.toUpperCase() ?? 'N/A',
                                      Icons.work,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Phone',
                                      _userProfile?['phoneNo'] ?? 'N/A',
                                      Icons.phone,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildSection(
                                  'Personal Information',
                                  [
                                    _buildInfoTile(
                                      'Father\'s Name',
                                      _userProfile?['fatherName'] ?? 'N/A',
                                      Icons.person,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Gender',
                                      _userProfile?['gender'] ?? 'N/A',
                                      Icons.people,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Date of Birth',
                                      _userProfile?['dob'] ?? 'N/A',
                                      Icons.calendar_today,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Aadhar Number',
                                      _userProfile?['aadharNo'] ?? 'N/A',
                                      Icons.credit_card,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildSection(
                                  'Location Details',
                                  [
                                    _buildInfoTile(
                                      'Zone ID',
                                      _userProfile?['zoneId'] ?? 'Not Assigned',
                                      Icons.location_on,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Sansad',
                                      '${_userProfile?['sansadName'] ?? 'N/A'} (${_userProfile?['sansadNo'] ?? 'N/A'})',
                                      Icons.house,
                                    ),
                                    _buildDivider(),
                                    _buildInfoTile(
                                      'Mouza',
                                      _userProfile?['mouzaName'] ?? 'N/A',
                                      Icons.place,
                                    ),
                                    if (_userProfile?['address'] != null) ...[
                                      _buildDivider(),
                                      _buildInfoTile(
                                        'Village',
                                        _userProfile?['address']['village'] ?? 'N/A',
                                        Icons.home,
                                      ),
                                      _buildDivider(),
                                      _buildInfoTile(
                                        'Gram Panchayat',
                                        _userProfile?['address']['gramPanchayat'] ?? 'N/A',
                                        Icons.location_city,
                                      ),
                                      _buildDivider(),
                                      _buildInfoTile(
                                        'Block',
                                        _userProfile?['address']['blockNo'] ?? 'N/A',
                                        Icons.grid_view,
                                      ),
                                      _buildDivider(),
                                      _buildInfoTile(
                                        'District',
                                        _userProfile?['address']['district'] ?? 'N/A',
                                        Icons.map,
                                      ),
                                      _buildDivider(),
                                      _buildInfoTile(
                                        'Pin Code',
                                        _userProfile?['address']['pinCode'] ?? 'N/A',
                                        Icons.pin_drop,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade700,
                                        Colors.red.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade200.withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _logout,
                                    icon: const Icon(Icons.logout, size: 20),
                                    label: const Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade800,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade800,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}