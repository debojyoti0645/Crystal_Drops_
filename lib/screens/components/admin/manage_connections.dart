import 'package:flutter/material.dart';

import '../../../service/api_service.dart';

class ManageConnectionsScreen extends StatefulWidget {
  const ManageConnectionsScreen({super.key});

  @override
  State<ManageConnectionsScreen> createState() =>
      _ManageConnectionsScreenState();
}

class _ManageConnectionsScreenState extends State<ManageConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _connections = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndFetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndFetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.initializeAuthToken();
      await _fetchConnections();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchConnections() async {
    try {
      final response = await _apiService.getAllUsersWithConnection();

      if (response['success']) {
        if (mounted) {
          setState(() {
            _connections = List<Map<String, dynamic>>.from(
              response['connections'],
            );
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to fetch connections',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleConnectionStatus(Map<String, dynamic> connection) async {
    if (!mounted) return;

    final bool isActive = connection['status'] == 'active';
    final String connectionId = connection['connectionId'];

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isActive ? 'Deactivate Connection?' : 'Activate Connection?',
          ),
          content: Text(
            'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} this connection?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          isActive
              ? await _apiService.deactivateConnection(connectionId)
              : await _apiService.activateConnection(connectionId);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Connection status updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the connections list
        await _fetchConnections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to update connection status',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildConnectionCard(Map<String, dynamic> connection) {
    final bool isActive = connection['status'] == 'active';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isActive
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: Container(
            width: 70,
            height: 80,
            decoration: BoxDecoration(
              color:
                  isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isActive ? Colors.green : Colors.red,
              size: 28,
            ),
          ),
          title: Expanded(
            child: Text(
              connection['customerName'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${connection['connectionId'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    connection['connectionType'] ?? 'N/A',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: Switch(
            value: isActive,
            onChanged:
                _isLoading
                    ? null
                    : (bool value) => _toggleConnectionStatus(connection),
            activeColor: Colors.green,
          ),
          onTap: () => _showConnectionDetails(context, connection),
        ),
      ),
    );
  }

  void _showConnectionDetails(
    BuildContext context,
    Map<String, dynamic> connection,
  ) {
    final bool isActive = connection['status'] == 'active';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection['customerName'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Connection #${connection['connectionId']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'Status',
                    connection['status']?.toUpperCase() ?? 'N/A',
                    valueColor: isActive ? Colors.green : Colors.red,
                  ),
                  _detailRow(
                    'Connection Type',
                    connection['connectionType'] ?? 'N/A',
                  ),
                  _detailRow('Amount', connection['formattedAmount'] ?? 'N/A'),
                  _detailRow('Zone', connection['zoneId'] ?? 'N/A'),
                  if (connection['formattedCreatedAt'] != null) ...[
                    _detailRow(
                      'Created Date',
                      connection['formattedCreatedAt']['date'],
                    ),
                    _detailRow(
                      'Created Time',
                      connection['formattedCreatedAt']['time'],
                    ),
                  ],
                  const Divider(),
                  const Text(
                    'Address Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (connection['address'] != null) ...[
                    _detailRow(
                      'Village',
                      connection['address']['village'] ?? 'N/A',
                    ),
                    _detailRow(
                      'District',
                      connection['address']['district'] ?? 'N/A',
                    ),
                    _detailRow(
                      'Police Station',
                      connection['address']['policeStation'] ?? 'N/A',
                    ),
                    _detailRow(
                      'Pin Code',
                      connection['address']['pinCode'] ?? 'N/A',
                    ),
                    _detailRow(
                      'Block No',
                      connection['address']['blockNo'] ?? 'N/A',
                    ),
                    _detailRow(
                      'Gram Panchayat',
                      connection['address']['gramPanchayat'] ?? 'N/A',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _toggleConnectionStatus(connection);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isActive ? Colors.red : Colors.green,
                ),
                child: Text(isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black54,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeConnections =
        _connections.where((c) => c['status'] == 'active').toList();
    final inactiveConnections =
        _connections.where((c) => c['status'] != 'active').toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Connections',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
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
              labelColor: Colors.white,
              unselectedLabelColor: Colors.orange.shade100,
              controller: _tabController,
              indicatorColor: Colors.orange,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.check_circle_outline),
                  text: 'Active (${activeConnections.length})',
                ),
                Tab(
                  icon: const Icon(Icons.cancel_outlined),
                  text: 'Inactive (${inactiveConnections.length})',
                ),
              ],
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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConnectionList(activeConnections, 'active'),
                    _buildConnectionList(inactiveConnections, 'inactive'),
                  ],
                ),
      ),
    );
  }

  Widget _buildConnectionList(
    List<Map<String, dynamic>> connections,
    String type,
  ) {
    if (connections.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _initializeAndFetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(1),
        itemCount: connections.length,
        itemBuilder:
            (context, index) => _buildConnectionCard(connections[index]),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'active'
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 64,
            color: Colors.blue.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${type} connections found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blue.shade300,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
