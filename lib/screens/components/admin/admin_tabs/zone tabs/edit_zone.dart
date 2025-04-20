import 'package:flutter/material.dart';

import '../../../../../service/api_service.dart';

class EditZonesTab extends StatefulWidget {
  const EditZonesTab({Key? key}) : super(key: key);

  @override
  State<EditZonesTab> createState() => _EditZonesTabState();
}

class _EditZonesTabState extends State<EditZonesTab> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _zones = [];
  List<dynamic> _filteredZones = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchZones();
    _fetchAvailableUsers();
  }

  Future<void> _fetchZones() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _apiService.initializeAuthToken();
      final token = _apiService.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Please login to edit zones';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getAllZones();

      if (!mounted) return;
      setState(() {
        if (response['success']) {
          _zones = response['zones'];
          _filteredZones = _zones;
          _errorMessage = '';
        } else {
          _errorMessage = response['message'];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to fetch zones: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAvailableUsers() async {
    if (!mounted) return;

    setState(() {
    });

    try {
      final response = await _apiService.getApprovedAccounts();
      if (response['success']) {
        setState(() {
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  void _filterZones(String query) {
    setState(() {
      _filteredZones =
          _zones.where((zone) {
            final zoneId = zone['zoneId'].toString().toLowerCase();
            final address = zone['zonalAddress'].toString().toLowerCase();
            final searchLower = query.toLowerCase();
            return zoneId.contains(searchLower) ||
                address.contains(searchLower);
          }).toList();
    });
  }

  Future<void> _showEditDialog(Map<String, dynamic> zone) async {
    final TextEditingController addressController = TextEditingController(
      text: zone['zonalAddress'],
    );

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Edit Zone ${zone['zoneId']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Zonal Address',
                    hintText: 'Enter new address for the zone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  try {
                    final response = await _apiService.updateZone(
                      zoneId: zone['zoneId'],
                      zonalAddress: addressController.text.trim(),
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response['success']
                              ? 'Zone updated successfully'
                              : response['message'] ?? 'Failed to update zone',
                        ),
                        backgroundColor:
                            response['success'] ? Colors.green : Colors.red,
                      ),
                    );

                    if (response['success'] && mounted) {
                      _fetchZones();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating zone: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search zones by ID or address...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterZones,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchZones,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : _filteredZones.isEmpty
                  ? const Center(child: Text('No zones found'))
                  : RefreshIndicator(
                    onRefresh: _fetchZones,
                    child: ListView.builder(
                      itemCount: _filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredZones[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.location_on),
                            ),
                            title: Text(
                              'Zone ID: ${zone['zoneId']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Address: ${zone['zonalAddress']}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Distributors: ${zone['assignedDistributors']?.length ?? 0}',
                                    ),
                                    Text(
                                      'Delivery Partners: ${zone['assignedDeliveryPartners']?.length ?? 0}',
                                    ),
                                    Text(
                                      'Customers: ${zone['customers']?.length ?? 0}',
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit'),
                                          onPressed:
                                              () => _showEditDialog(zone),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
