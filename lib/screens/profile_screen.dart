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
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: Colors.blue.shade800,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 300,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            children: [
                              // Gradient Background
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade900,
                                      Colors.blue.shade800,
                                      Colors.indigo.shade700,
                                    ],
                                  ),
                                ),
                              ),
                              // Animated Wave Pattern
                              Positioned.fill(
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ).createShader(bounds),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://www.transparenttextures.com/patterns/waves.png',
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
                                  const SizedBox(height: 60),
                                  // Avatar with Glowing Effect
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.shade300.withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 55,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          _userProfile?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Name with Shadow
                                  Text(
                                    _userProfile?['name'] ?? 'User',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Role Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _userProfile?['role']?.toUpperCase() ?? 'USER',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Info Sections
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                            child: Column(
                              children: [
                                _buildEnhancedSection(
                                  'Account Information',
                                  Icons.person_outline,
                                  [
                                    _buildEnhancedInfoTile(
                                      'Account ID',
                                      _userProfile?['accountId'] ?? 'N/A',
                                      Icons.badge,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Role',
                                      _userProfile?['role']?.toUpperCase() ?? 'N/A',
                                      Icons.work,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Phone',
                                      _userProfile?['phoneNo'] ?? 'N/A',
                                      Icons.phone,
                                    ),
                                  ],
                                ),
                                _buildEnhancedSection(
                                  'Personal Information',
                                  Icons.info_outline,
                                  [
                                    _buildEnhancedInfoTile(
                                      'Father\'s Name',
                                      _userProfile?['fatherName'] ?? 'N/A',
                                      Icons.person,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Gender',
                                      _userProfile?['gender'] ?? 'N/A',
                                      Icons.people,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Date of Birth',
                                      _userProfile?['dob'] ?? 'N/A',
                                      Icons.calendar_today,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Aadhar Number',
                                      _userProfile?['aadharNo'] ?? 'N/A',
                                      Icons.credit_card,
                                    ),
                                  ],
                                ),
                                _buildEnhancedSection(
                                  'Location Details',
                                  Icons.location_on,
                                  [
                                    _buildEnhancedInfoTile(
                                      'Zone ID',
                                      _userProfile?['zoneId'] ?? 'Not Assigned',
                                      Icons.location_on,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Sansad',
                                      '${_userProfile?['sansadName'] ?? 'N/A'} (${_userProfile?['sansadNo'] ?? 'N/A'})',
                                      Icons.house,
                                    ),
                                    _buildEnhancedInfoTile(
                                      'Mouza',
                                      _userProfile?['mouzaName'] ?? 'N/A',
                                      Icons.place,
                                    ),
                                    if (_userProfile?['address'] != null) ...[
                                      _buildEnhancedInfoTile(
                                        'Village',
                                        _userProfile?['address']['village'] ?? 'N/A',
                                        Icons.home,
                                      ),
                                      _buildEnhancedInfoTile(
                                        'Gram Panchayat',
                                        _userProfile?['address']['gramPanchayat'] ?? 'N/A',
                                        Icons.location_city,
                                      ),
                                      _buildEnhancedInfoTile(
                                        'Block',
                                        _userProfile?['address']['blockNo'] ?? 'N/A',
                                        Icons.grid_view,
                                      ),
                                      _buildEnhancedInfoTile(
                                        'District',
                                        _userProfile?['address']['district'] ?? 'N/A',
                                        Icons.map,
                                      ),
                                      _buildEnhancedInfoTile(
                                        'Pin Code',
                                        _userProfile?['address']['pinCode'] ?? 'N/A',
                                        Icons.pin_drop,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 32),
                                _buildLogoutButton(),
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

  Widget _buildLoadingState() {
    return Center(
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
    );
  }

  Widget _buildErrorState() {
    return Center(
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
    );
  }

  Widget _buildEnhancedSection(String title, IconData titleIcon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    titleIcon,
                    color: Colors.blue.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade800,
              size: 22,
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
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade700,
            Colors.red.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, size: 22),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}