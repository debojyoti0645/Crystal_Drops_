import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_supply/service/api_service.dart';

class AllTransactionScreen extends StatefulWidget {
  const AllTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AllTransactionScreen> createState() => _AllTransactionScreenState();
}

class _AllTransactionScreenState extends State<AllTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndFetchOrders();
  }

  Future<void> _initializeAndFetchOrders() async {
    try {
      await _apiService.initializeAuthToken();
      _fetchOrders();
    } catch (e) {
      setState(() {
        _error = 'Error initializing: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = _apiService.getAuthToken();
      if (token == null) {
        setState(() {
          _error = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      _apiService.setAuthToken(token);
      final response = await _apiService.getAllOrders();
      
      if (response['success']) {
        final orders = List<dynamic>.from(response['orders']);
        orders.sort((a, b) {
          final aDate = DateTime.parse(a['formattedCreatedAt']['timestamp']);
          final bDate = DateTime.parse(b['formattedCreatedAt']['timestamp']);
          return bDate.compareTo(aDate);
        });

        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to fetch orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredOrders(String status) {
    return _allOrders.where((order) => order['payStatus'] == status).toList();
  }

  Widget _buildTransactionCard(dynamic order) {
    final createdAt = DateTime.parse(order['formattedCreatedAt']['timestamp']);
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
    
    // Extract data from the correct fields
    final orderId = order['orderId'] ?? 'N/A';
    final buyerId = order['buyer'] ?? 'N/A';
    final buyerName = order['buyerName'] ?? 'N/A';
    final buyerRole = order['buyerRole']?.toString().toUpperCase() ?? 'N/A';
    final amount = order['formattedAmount'] ?? '₹${order['totalAmount'] ?? 0}';
    final quantity = order['quantity']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: order['payStatus'] == 'completed' ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            Icons.receipt,
            color: order['payStatus'] == 'completed' ? Colors.green : Colors.orange,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #$orderId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$buyerName (ID: $buyerId)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Role: $buyerRole',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Date: $formattedDate',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Order ID', orderId),
                _buildDetailRow('Customer Name', buyerName),
                _buildDetailRow('Customer ID', buyerId),
                _buildDetailRow('Role', buyerRole),
                _buildDetailRow('Amount', amount),
                _buildDetailRow('Quantity', quantity),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(
                      'Payment',
                      order['payStatus'] ?? 'pending',
                      order['payStatus'] == 'completed' ? Colors.green : Colors.orange,
                    ),
                    _buildStatusChip(
                      'Delivery',
                      order['deliveryStatus'] ?? 'pending',
                      order['deliveryStatus'] == 'completed'
                          ? Colors.green
                          : order['deliveryStatus'] == 'on_the_way'
                              ? Colors.blue
                              : Colors.orange,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String status, Color color) {
    return Chip(
      label: Text(
        '$label: ${status.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildOrdersList(String status) {
    final filteredOrders = _getFilteredOrders(status);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text('No ${status.toLowerCase()} orders found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(filteredOrders[index]);
        },
      ),
    );
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
            'All Transactions',
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
                      Icons.pending_actions,
                      color: Colors.orange.shade300,
                    ),
                    text: 'Pending',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade300,
                    ),
                    text: 'Completed',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList('pending'),
                      _buildOrdersList('completed'),
                    ],
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}