import 'package:flutter/material.dart';

import '../../../../../service/api_service.dart';

class ViewZonesTab extends StatefulWidget {
  const ViewZonesTab({Key? key}) : super(key: key);

  @override
  State<ViewZonesTab> createState() => _ViewZonesTabState();
}

class _ViewZonesTabState extends State<ViewZonesTab> {
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
  }

  Future<void> _fetchZones() async {
    try {
      if (!mounted) return; // Add mounted check
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _apiService.initializeAuthToken();

      final token = _apiService.getAuthToken();
      if (token == null) {
        if (!mounted) return; // Add mounted check
        setState(() {
          _errorMessage = 'Please login to view zones';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getAllZones();

      if (!mounted) return; // Add mounted check

      setState(() {
        if (response['success']) {
          _zones = response['zones'];
          _filteredZones = _zones;
        } else {
          _errorMessage = response['message'];
        }
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return; // Add mounted check
      setState(() {
        _errorMessage = 'Failed to fetch zones: $e';
        _isLoading = false;
      });
    }
  }

  void _filterZones(String query) {
    if (!mounted) return; // Add mounted check
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search zones by ID or address...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterZones,
            ),
            const SizedBox(height: 16),

            // Zones List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : _filteredZones.isEmpty
                      ? const Center(child: Text('No zones found'))
                      : ListView.builder(
                        itemCount: _filteredZones.length,
                        itemBuilder: (context, index) {
                          final zone = _filteredZones[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                'Zone ID: ${zone['zoneId']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Address: ${zone['zonalAddress']}'),
                                  Text(
                                    'Distributors: ${zone['assignedDistributors']?.length ?? 0}',
                                  ),
                                  Text(
                                    'Delivery Partners: ${zone['assignedDeliveryPartners']?.length ?? 0}',
                                  ),
                                  Text(
                                    'Customers: ${zone['customers']?.length ?? 0}',
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),

                              onTap: () => _showZoneDetailsDialog(zone),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showZoneDetailsDialog(Map<String, dynamic> zone) {
    Widget _buildUserList(String title, List<dynamic> users) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (users.isEmpty)
            Text('No ${title.toLowerCase()} assigned')
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, 
                          size: 16, 
                          color: Theme.of(context).primaryColor
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '#${user['id'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zone ${zone['zoneId']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(zone['zonalAddress'] ?? 'N/A'),
              const SizedBox(height: 16),
              _buildUserList('Distributors', zone['assignedDistributors'] ?? []),
              _buildUserList('Delivery Partners', zone['assignedDeliveryPartners'] ?? []),
              _buildUserList('Customers', zone['customers'] ?? []),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
