import 'package:flutter/material.dart';

import '../../../service/api_service.dart';

class AssignedOrders extends StatefulWidget {
  const AssignedOrders({super.key});

  @override
  State<AssignedOrders> createState() => _AssignedOrdersState();
}

class _AssignedOrdersState extends State<AssignedOrders> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedRole;
  final List<String> _userRoles = ['All', 'customer', 'distributor'];

  List<Map<String, dynamic>> get filteredAndSortedOrders {
    List<Map<String, dynamic>> result = List.from(_orders);
    
    // Apply role filter
    if (_selectedRole != null && _selectedRole != 'All') {
      result = result.where((order) => 
        order['buyerRole']?.toString().toLowerCase() == _selectedRole?.toLowerCase()
      ).toList();
    }
    
    // Sort by createdAt timestamp in descending order (most recent first)
    result.sort((a, b) {
      final aDate = _getDateTimeFromTimestamp(a['createdAt']);
      final bDate = _getDateTimeFromTimestamp(b['createdAt']);
      return bDate.compareTo(aDate); // Descending order
    });
    
    return result;
  }

  DateTime _getDateTimeFromTimestamp(Map<String, dynamic> timestamp) {
    final seconds = timestamp['_seconds'] as int;
    final nanoseconds = timestamp['_nanoseconds'] as int;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + (nanoseconds / 1000000).round(),
    );
  }

  String _getRelativeDate(DateTime orderDate) {
    final now = DateTime.now();
    final difference = now.difference(orderDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays <= 7) {
      return 'Last Week';
    } else if (difference.inDays <= 30) {
      return 'Last Month';
    } else {
      return 'Older';
    }
  }

  Map<String, List<Map<String, dynamic>>> get groupedOrders {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final orderedGroups = ['Today', 'Yesterday', 'Last Week', 'Last Month', 'Older'];
    
    // Initialize empty lists for all groups
    for (var group in orderedGroups) {
      groups[group] = [];
    }
    
    // Sort and group orders
    for (var order in filteredAndSortedOrders) {
      final orderDate = _getDateTimeFromTimestamp(order['createdAt']);
      final group = _getRelativeDate(orderDate);
      groups[group]!.add(order);
    }
    
    return Map.fromEntries(
      groups.entries.where((entry) => entry.value.isNotEmpty)
    );
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize auth token first
      await _apiService.initializeAuthToken();
      await _loadOrders();
    } catch (e) {
      debugPrint('Error in initialization: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to initialize: ${e.toString()}';
      });
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      
      final token = _apiService.getAuthToken();
      debugPrint('Current auth token: $token');
      
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Authentication token not found. Please login again.';
        });
        return;
      }

      // Fetch user profile
      final profileResult = await _apiService.getUserProfile();
      debugPrint('Profile Result: $profileResult');
      
      if (!profileResult['success']) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load user profile: ${profileResult['message']}';
        });
        return;
      }

      // Extract zone ID from profile result
      final userData = profileResult['user'];
      if (userData == null || userData['zoneId'] == null || userData['zoneId'].isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No zone assigned to user';
        });
        return;
      }

      final String zoneId = userData['zoneId'];
      debugPrint('Found zone ID: $zoneId');
      
      final result = await _apiService.getDeliveryOrdersByZone(zoneId);
      
      if (result['success']) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(result['orders']);
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
      debugPrint('Error in _loadOrders: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load orders: ${e.toString()}';
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String deliveryStatus, String payStatus) async {
    try {
      final result = await _apiService.updateOrderStatus(
        orderId: orderId,
        deliveryStatus: deliveryStatus,
        payStatus: payStatus,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        await _loadOrders(); // Refresh the orders list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDialog(Map<String, dynamic> order) {
    String selectedDeliveryStatus = 'delivered';
    // Initialize payment status based on current order status
    String selectedPaymentStatus = order['payStatus'] ?? 'pending';
    bool isPaymentCompleted = order['payStatus'] == 'completed';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order #${order['orderId']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${order['buyerName'] ?? 'Unknown'}'),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${order['buyer']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${order['buyerRole'] ?? 'Customer'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showUserAddressDialog(order['buyer']),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Address'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                  ],
                ),
                Text('Amount: ${order['formattedAmount']}'),
                Text('Current Status: ${order['deliveryStatus'].toString().toUpperCase()}'),
                Text('Payment Status: ${order['payStatus']?.toString().toUpperCase() ?? 'PENDING'}'),
                const SizedBox(height: 20),
                if (!order['isCompleted']) ...[
                  const Text('Update Delivery Status:'),
                  DropdownButton<String>(
                    value: selectedDeliveryStatus,
                    isExpanded: true,
                    items: ['delivered', 'failed'].map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedDeliveryStatus = newValue;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Payment Status:'),
                  if (isPaymentCompleted) 
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    DropdownButton<String>(
                      value: selectedPaymentStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'pending',
                          child: Text('PENDING'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'completed',
                          child: Text('COMPLETED'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedPaymentStatus = newValue;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _updateOrderStatus(
                          order['orderId'],
                          selectedDeliveryStatus,
                          selectedPaymentStatus,
                        );
                      },
                      child: const Text(
                        'Update Order Status',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
          ],
        );
      },
    );
  }

  void _showUserAddressDialog(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Get the role from the order data
    final order = _orders.firstWhere(
      (order) => order['buyer'] == userId,
      orElse: () => {'buyerRole': 'customer'}, // default to customer if not found
    );
    final role = order['buyerRole']?.toString().toLowerCase() ?? 'customer';

    final result = await _apiService.getUserInfo(userId, role);
    Navigator.pop(context); // Dismiss loading dialog

    if (result['success'] && result['user'] != null) {
      final user = result['user'];
      final address = user['address'] as Map<String, dynamic>;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delivery Address'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${user['name']}'),
                const SizedBox(height: 8),
                Text('Role: ${role.toUpperCase()}'),
                const SizedBox(height: 8),
                Text('Village: ${address['village'] ?? 'N/A'}'),
                Text('Gram Panchayat: ${address['gramPanchayat'] ?? 'N/A'}'),
                Text('Block No: ${address['blockNo'] ?? 'N/A'}'),
                Text('Police Station: ${address['policeStation'] ?? 'N/A'}'),
                Text('District: ${address['district'] ?? 'N/A'}'),
                Text('Pin Code: ${address['pinCode'] ?? 'N/A'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user address: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'ASSIGNED ORDERS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String role) {
              setState(() {
                _selectedRole = role == 'All' ? null : role;
              });
            },
            itemBuilder: (BuildContext context) {
              return _userRoles.map((String role) {
                return PopupMenuItem<String>(
                  value: role,
                  child: Row(
                    children: [
                      Icon(
                        role == (_selectedRole ?? 'All') 
                            ? Icons.radio_button_checked 
                            : Icons.radio_button_unchecked,
                        color: role == (_selectedRole ?? 'All') 
                            ? Colors.blue 
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(role.toUpperCase()),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade50],
          ),
        ),
        child: Column(
          children: [
            if (_selectedRole != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('Filter: ${_selectedRole!.toUpperCase()}'),
                      onDeleted: () {
                        setState(() {
                          _selectedRole = null;
                        });
                      },
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
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
                                onPressed: _initialize,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _initialize,
                          child: _orders.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No orders assigned',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: groupedOrders.length,
                                  itemBuilder: (context, groupIndex) {
                                    final groupTitle = groupedOrders.keys.elementAt(groupIndex);
                                    final groupOrders = groupedOrders[groupTitle]!;
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            groupTitle,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        ...groupOrders.map((order) => Card(
                                          elevation: 4,
                                          margin: const EdgeInsets.only(bottom: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: InkWell(
                                            onTap: () => _showOrderDialog(order),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Order #${order['orderId']}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: order['isPending']
                                                              ? Colors.orange
                                                              : Colors.green,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          order['deliveryStatus']
                                                              .toString()
                                                              .toUpperCase(),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    _getDateTimeFromTimestamp(order['createdAt'])
                                                        .toLocal()
                                                        .toString()
                                                        .split('.')[0], // Format: YYYY-MM-DD HH:mm:ss
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const Divider(),
                                                  ListTile(
                                                    contentPadding: EdgeInsets.zero,
                                                    leading: const Icon(
                                                      Icons.person_outline,
                                                      color: Colors.blue,
                                                    ),
                                                    title: Text(
                                                      order['buyerName'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    subtitle: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'ID: ${order['buyer']}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Role: ${order['buyerRole'] ?? 'Customer'}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    trailing: Text(
                                                      order['formattedAmount'].toString(),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )).toList(),
                                      ],
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
