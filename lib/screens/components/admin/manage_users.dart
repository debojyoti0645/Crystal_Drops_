import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/service/api_service.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.amber,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          controller: _tabController,
          tabs: const [Tab(text: 'All Users'), Tab(text: 'Pending Requests')],
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
          children: [
            // All Users Tab
            AllUsersTab(),
            // Pending Requests Tab
            PendingRequestsTab(),
          ],
        ),
      ),
    );
  }
}

class AllUsersTab extends StatefulWidget {
  const AllUsersTab({super.key});

  @override
  State<AllUsersTab> createState() => _AllUsersTabState();
}

// All Users Tab
class _AllUsersTabState extends State<AllUsersTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _approvedAccounts = [];
  List<dynamic> _filteredAccounts = [];
  bool _isLoading = true;
  String _error = '';
  bool _mounted = true; // Add this flag

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  @override
  void dispose() {
    _mounted = false; // Set flag to false when disposed
    super.dispose();
  }

  Future<void> _initializeAndFetch() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      
      if (token != null) {
        _apiService.setAuthToken(token);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login again'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      await _fetchApprovedAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchApprovedAccounts() async {
    if (!_mounted) return; // Early return if not mounted

    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getApprovedAccounts();

      if (!_mounted) return; // Check again after async operation

      if (response['success']) {
        setState(() {
          _approvedAccounts = response['data'];
          _filteredAccounts = _approvedAccounts;
          _error = '';
        });
      } else {
        setState(() => _error = response['message']);
      }
    } catch (e) {
      if (!_mounted) return;
      setState(() => _error = 'Failed to load approved accounts');
    } finally {
      if (!_mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterAccounts(String query) {
    if (!_mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredAccounts = _approvedAccounts;
      } else {
        _filteredAccounts =
            _approvedAccounts.where((account) {
              final name = account['name']?.toLowerCase() ?? '';
              final accountId = account['accountId']?.toString() ?? '';
              return name.contains(query.toLowerCase()) ||
                  accountId.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name..',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterAccounts,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String role) {
              _filterByRole(role);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'All', child: Text('All Roles')),
                const PopupMenuItem(value: 'Admin', child: Text('Admin')),
                const PopupMenuItem(value: 'Customer', child: Text('Customer')),
                const PopupMenuItem(
                  value: 'Distributor',
                  child: Text('Distributor'),
                ),
                const PopupMenuItem(
                  value: 'Delivery',
                  child: Text('Delivery'),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  void _filterByRole(String role) {
    if (!_mounted) return;
    setState(() {
      if (role == 'All') {
        _filteredAccounts = _approvedAccounts;
      } else {
        _filteredAccounts =
            _approvedAccounts.where((account) {
              final accountRole = account['role']?.toLowerCase() ?? '';
              return accountRole == role.toLowerCase();
            }).toList();
      }
    });
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final address = account['address'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(account['name'] ?? 'Unknown'),
        subtitle: Text('ID: ${account['accountId'] ?? 'N/A'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Phone', account['phoneNo']),
                _buildInfoRow('Role', account['role']),
                _buildInfoRow('Father\'s Name', account['fatherName']),
                _buildInfoRow('Gender', account['gender']),
                _buildInfoRow('DOB', account['dob']),
                _buildInfoRow('Aadhar', account['aadharNo']),
                _buildInfoRow('Zone', account['zoneId'] ?? 'Not Assigned'),
                const Divider(),
                const Text(
                  'Address:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildInfoRow('Village', address['village']),
                _buildInfoRow('Gram Panchayat', address['gramPanchayat']),
                _buildInfoRow('Block', address['blockNo']),
                _buildInfoRow('District', address['district']),
                _buildInfoRow('PIN', address['pinCode']),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error.isNotEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchApprovedAccounts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredAccounts.isEmpty)
          const Expanded(
            child: Center(child: Text('No approved accounts found')),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchApprovedAccounts,
              child: ListView.builder(
                itemCount: _filteredAccounts.length,
                itemBuilder: (context, index) {
                  return _buildAccountCard(_filteredAccounts[index]);
                },
              ),
            ),
          ),
      ],
    );
  }
}

// Pending Requests Tab
class PendingRequestsTab extends StatefulWidget {
  const PendingRequestsTab({super.key});

  @override
  State<PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<PendingRequestsTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _pendingAccounts = [];
  List<dynamic> _filteredPendingAccounts = [];
  bool _isLoading = true;
  String _error = '';
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _initializeAndFetch() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      
      if (token != null) {
        _apiService.setAuthToken(token);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login again'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      await _fetchPendingAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchPendingAccounts() async {
    if (!_mounted) return;

    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getPendingAccounts();

      if (!_mounted) return;

      if (response['success']) {
        setState(() {
          _pendingAccounts = response['data'];
          _filteredPendingAccounts = _pendingAccounts;
          _error = '';
        });
      } else {
        setState(() => _error = response['message']);
      }
    } catch (e) {
      if (!_mounted) return;
      setState(() => _error = 'Failed to load pending accounts');
    } finally {
      if (!_mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterPendingAccounts(String query) {
    if (!_mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredPendingAccounts = _pendingAccounts;
      } else {
        _filteredPendingAccounts =
            _pendingAccounts.where((account) {
              final name = account['name']?.toLowerCase() ?? '';
              final accountId = account['accountId']?.toString() ?? '';
              return name.contains(query.toLowerCase()) ||
                  accountId.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterPendingAccounts,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String role) {
              _filterByRole(role);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'All', child: Text('All Roles')),
                const PopupMenuItem(value: 'Admin', child: Text('Admin')),
                const PopupMenuItem(value: 'Customer', child: Text('Customer')),
                const PopupMenuItem(
                  value: 'Distributor',
                  child: Text('Distributor'),
                ),
                const PopupMenuItem(value: 'Delivery', child: Text('Delivery')),
              ];
            },
          ),
        ],
      ),
    );
  }

  void _filterByRole(String role) {
    if (!_mounted) return;
    setState(() {
      if (role == 'All') {
        _filteredPendingAccounts = _pendingAccounts;
      } else {
        _filteredPendingAccounts =
            _pendingAccounts.where((account) {
              final accountRole = account['role']?.toLowerCase() ?? '';
              return accountRole == role.toLowerCase();
            }).toList();
      }
    });
  }

  // Add this method to show the zone selection dialog
  Future<String?> _showZoneSelectionDialog(BuildContext context) async {
    List<Map<String, dynamic>> zones = [];
    String? selectedZoneId;
    bool isLoading = true;
    String error = '';

    return showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Load zones when dialog opens
            if (isLoading) {
              _apiService.getAllZones().then((response) {
                setState(() {
                  isLoading = false;
                  if (response['success']) {
                    zones = List<Map<String, dynamic>>.from(response['zones']);
                  } else {
                    error = response['message'] ?? 'Failed to load zones';
                  }
                });
              });
            }

            return AlertDialog(
              title: const Text('Select Zone'),
              content: SizedBox(
                width: double.maxFinite,
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : error.isNotEmpty
                        ? Text(error, style: const TextStyle(color: Colors.red))
                        : zones.isEmpty
                        ? const Text('No zones available')
                        : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                zones.map((zone) {
                                  return RadioListTile<String>(
                                    title: Text(
                                      zone['zonalAddress'] ?? 'Unknown Zone',
                                    ),
                                    subtitle: Text(
                                      'Zone ID: ${zone['zoneId'] ?? 'N/A'}',
                                    ),
                                    value: zone['zoneId'],
                                    groupValue: selectedZoneId,
                                    onChanged: (String? value) {
                                      setState(() => selectedZoneId = value);
                                    },
                                  );
                                }).toList(),
                          ),
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      selectedZoneId == null
                          ? null
                          : () => Navigator.of(context).pop(selectedZoneId),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Update the _approveAccount method to show zone selection first
  Future<void> _approveAccount(String userId, String role) async {
    // Show zone selection dialog first
    final selectedZoneId = await _showZoneSelectionDialog(context);

    if (selectedZoneId == null) return; // User cancelled

    try {
      final response = await _apiService.approveAccount(
        userId,
        role,
        selectedZoneId,
      );

      if (!_mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['success']
                ? response['message'] ?? 'Account approved successfully'
                : response['message'] ?? 'Failed to approve account',
          ),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        ),
      );

      if (response['success']) {
        await _fetchPendingAccounts();
      }
    } catch (e) {
      if (!_mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error approving account'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final address = account['address'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(account['name'] ?? 'Unknown'),
        subtitle: Text('ID: ${account['accountId'] ?? 'N/A'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Phone', account['phoneNo']),
                _buildInfoRow('Role', account['role']),
                _buildInfoRow('Father\'s Name', account['fatherName']),
                _buildInfoRow('Gender', account['gender']),
                _buildInfoRow('DOB', account['dob']),
                _buildInfoRow('Aadhar', account['aadharNo']),
                const Divider(),
                const Text(
                  'Address:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildInfoRow('Village', address['village']),
                _buildInfoRow('Gram Panchayat', address['gramPanchayat']),
                _buildInfoRow('Block', address['blockNo']),
                _buildInfoRow('District', address['district']),
                _buildInfoRow('PIN', address['pinCode']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        final accountId = account['accountId']?.toString();
                        final role = account['role']?.toString();

                        if (accountId != null && role != null) {
                          _approveAccount(accountId, role);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid account data'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          final response = await _apiService.rejectAccount(
                            account['accountId'],
                            account['role'],
                          );

                          if (response['success']) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Account rejected successfully'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            await _fetchPendingAccounts();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  response['message'] ??
                                      'Failed to reject account',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'An error occurred while rejecting the account',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error.isNotEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPendingAccounts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredPendingAccounts.isEmpty)
          const Expanded(
            child: Center(child: Text('No pending accounts found')),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPendingAccounts,
              child: ListView.builder(
                itemCount: _filteredPendingAccounts.length,
                itemBuilder: (context, index) {
                  return _buildAccountCard(_filteredPendingAccounts[index]);
                },
              ),
            ),
          ),
      ],
    );
  }
}
