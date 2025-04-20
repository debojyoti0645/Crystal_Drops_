import 'package:flutter/material.dart';

import '../../../service/api_service.dart';

class DeliveryHistory extends StatefulWidget {
  const DeliveryHistory({super.key});

  @override
  State<DeliveryHistory> createState() => _DeliveryHistoryState();
}

class _DeliveryHistoryState extends State<DeliveryHistory> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;
  String? _error;
  String? _userZone;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadOrders();
  }

  Future<void> _initializeAndLoadOrders() async {
    try {
      setState(() => _isLoading = true);
      
      // Initialize auth token first
      await _apiService.initializeAuthToken();

      // Check if token is available
      final token = _apiService.getAuthToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Authentication token not found';
        });
        return;
      }

      // Get user profile to fetch zone ID
      final profileResult = await _apiService.getUserProfile();
      if (!profileResult['success']) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load user profile';
        });
        return;
      }

      // Extract zoneId from user profile - Changed from 'zone' to 'zoneId'
      final userZone = profileResult['user']['zoneId'];
      if (userZone == null || userZone.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No zone assigned to your account';
        });
        return;
      }

      debugPrint('Found zone ID: $userZone'); // Add debug print to verify zone

      _userZone = userZone; // Store zone ID
      await _loadCompletedOrders();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to initialize: ${e.toString()}';
      });
    }
  }

  Future<void> _loadCompletedOrders() async {
    try {
      if (_userZone == null) {
        setState(() {
          _isLoading = false;
          _error = 'No zone assigned to delivery partner';
        });
        return;
      }

      // Now fetch completed orders for this zone
      final result = await _apiService.getCompletedOrdersByZone(_userZone!);

      if (result['success']) {
        final orders = List<Map<String, dynamic>>.from(result['orders']);

        debugPrint('Total completed orders received: ${orders.length}');
        for (var order in orders) {
          debugPrint('Order ID: ${order['orderId']}');
          debugPrint('Buyer: ${order['buyerName']}');
          debugPrint('Amount: ${order['formattedAmount']}');
          debugPrint('Created At: ${order['formattedCreatedAt']['date']}');
          debugPrint('-------------------');
        }

        setState(() {
          _completedOrders = orders;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = result['message'];
        });
      }
    } catch (e) {
      debugPrint('Error loading completed orders: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load delivery history';
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Map && timestamp.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        timestamp['_seconds'] * 1000 + (timestamp['_nanoseconds'] ~/ 1000000),
      ).toString().split(' ')[0];
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'DELIVERY HISTORY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade50],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                        onPressed: _initializeAndLoadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _initializeAndLoadOrders,
                  child:
                      _completedOrders.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No completed deliveries yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _completedOrders.length,
                            itemBuilder: (context, index) {
                              final order = _completedOrders[index];
                              
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #${order['orderId']}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            order['formattedCreatedAt']['date'] ?? 
                                              _formatDate(order['createdAt']),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Customer: ${order['buyerName'] ?? order['buyer']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Quantity: ${order['quantity']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'Payment Status: ${order['payStatus']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          order['formattedAmount'] ?? 
                                            '₹${order['totalAmount']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}
