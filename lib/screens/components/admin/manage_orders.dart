import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

class ManageOrders extends StatefulWidget {
  const ManageOrders({super.key});

  @override
  State<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<ManageOrders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _zones = [];
  String? _selectedZone;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
    _loadZones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    try {
      await _apiService.initializeAuthToken(); // Ensure auth token is initialized
      final response = await _apiService.getAllZones();
      
      if (response['success']) {
        setState(() {
          _zones = response['zones'] as List<dynamic>;
          debugPrint('Loaded zones: $_zones');
        });
      } else {
        debugPrint('Failed to load zones: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error loading zones: $e');
    }
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    return orders.where((order) {
      // Filter by zone if selected
      if (_selectedZone != null && _selectedZone!.isNotEmpty) {
        if (order['zone'] != _selectedZone) {
          return false;
        }
      }

      // Filter by date range if selected
      if (_selectedFromDate != null || _selectedToDate != null) {
        final orderDate = DateTime.fromMillisecondsSinceEpoch(
          order['createdAt']['_seconds'] * 1000,
        );

        if (_selectedFromDate != null && orderDate.isBefore(_selectedFromDate!)) {
          return false;
        }

        if (_selectedToDate != null) {
          final endDate = _selectedToDate!.add(const Duration(days: 1));
          if (orderDate.isAfter(endDate)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      await _apiService.initializeAuthToken();
      final response = await _apiService.getAllOrders();

      if (response['success']) {
        setState(() {
          _orders = response['orders'];
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load orders';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading orders: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getPendingOrders() {
    return _orders
        .where(
          (order) =>
              order['payStatus'] == 'pending' &&
              order['deliveryStatus'] == 'pending',
        )
        .toList();
  }

  List<dynamic> _getInProgressOrders() {
    return _orders
        .where(
          (order) =>
              order['payStatus'] == 'completed' &&
              order['deliveryStatus'] == 'pending',
        )
        .toList();
  }

  List<dynamic> _getCompletedOrders() {
    return _orders
        .where(
          (order) =>
              order['payStatus'] == 'completed' &&
              order['deliveryStatus'] == 'delivered',
        )
        .toList();
  }

  List<dynamic> _sortOrdersByDate(List<dynamic> orders) {
    return List<dynamic>.from(orders)..sort((a, b) {
      final aSeconds = a['createdAt']['_seconds'] as int;
      final bSeconds = b['createdAt']['_seconds'] as int;
      return bSeconds.compareTo(aSeconds); // Descending order
    });
  }

  String _getGroupTitle(DateTime orderDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

    if (orderDay == today) {
      return 'Today';
    } else if (orderDay == yesterday) {
      return 'Yesterday';
    } else if (orderDay.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'Last 7 Days';
    } else if (orderDay.month == today.month && orderDay.year == today.year) {
      return 'This Month';
    } else {
      return '${orderDay.month}/${orderDay.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Orders',
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
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.orange.shade400,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              controller: _tabController,
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.pending_actions,
                    color: Colors.orange.shade300,
                  ),
                  text: 'Pending',
                ),
                Tab(
                  icon: Icon(Icons.local_shipping, color: Colors.blue.shade300),
                  text: 'In Progress',
                ),
                Tab(
                  icon: Icon(Icons.done_all, color: Colors.green.shade300),
                  text: 'Completed',
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
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading orders...',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : _errorMessage != null
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
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: _buildOrderList(_filterOrders(_getPendingOrders()), 'pending'),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: _buildOrderList(_filterOrders(_getInProgressOrders()), 'in_progress'),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: _buildOrderList(_filterOrders(_getCompletedOrders()), 'delivered'),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterDialog(context),
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String orderStatus) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue.shade300,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Sort orders by date
    final sortedOrders = _sortOrdersByDate(orders);

    // Group orders by date
    final Map<String, List<dynamic>> groupedOrders = {};

    for (var order in sortedOrders) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        order['createdAt']['_seconds'] * 1000,
      );
      final groupTitle = _getGroupTitle(createdAt);

      if (!groupedOrders.containsKey(groupTitle)) {
        groupedOrders[groupTitle] = [];
      }
      groupedOrders[groupTitle]!.add(order);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: groupedOrders.length,
        itemBuilder: (context, index) {
          final groupTitle = groupedOrders.keys.elementAt(index);
          final groupOrders = groupedOrders[groupTitle]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  groupTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              ...groupOrders
                  .map(
                    (order) => Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _getStatusColor(
                              orderStatus,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                orderStatus,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '#${sortedOrders.indexOf(order) + 1}',
                                style: TextStyle(
                                  color: _getStatusColor(orderStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                'Order \n#${order['orderId']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    orderStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  orderStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(orderStatus),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${order['buyerName']} (ID: ${order['buyer']})',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order['formattedCreatedAt']['date'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.payment,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order['formattedAmount'],
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Zone: ${order['zone'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showOrderDetails(context, order),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String orderStatus) {
    switch (orderStatus) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  'Order #${order['orderId']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow(
                    'Buyer',
                    '${order['buyerName']} (ID: ${order['buyer']})',
                  ),
                  _detailRow(
                    'Role',
                    order['buyerRole']?.toUpperCase() ?? 'N/A',
                  ),
                  _detailRow(
                    'Zone',
                    order['zone'] ?? 'N/A',
                    valueColor: Colors.blue.shade700,
                  ),
                  _detailRow('Order Date', order['formattedCreatedAt']['date']),
                  _detailRow('Order Time', order['formattedCreatedAt']['time']),
                  _detailRow('Total Amount', order['formattedAmount']),
                  _detailRow('Quantity', '${order['quantity']} items'),
                  const Divider(),
                  _detailRow(
                    'Payment Status',
                    order['payStatus']?.toUpperCase() ?? 'N/A',
                    valueColor: _getPaymentStatusColor(order['payStatus']),
                  ),
                  if (order['paymentUpdatedAt'] != null)
                    _detailRow(
                      'Last Payment Update',
                      order['formattedPaymentUpdatedAt']['date'],
                    ),
                  const Divider(),
                  _detailRow(
                    'Delivery Status',
                    order['deliveryStatus']?.toUpperCase() ?? 'N/A',
                    valueColor: _getDeliveryStatusColor(
                      order['deliveryStatus'],
                    ),
                  ),
                  const Divider(),
                  const Text(
                    'Products:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...order['products']
                      .map<Widget>(
                        (product) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Text('• $product'),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Add this helper method for detail rows
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

  // Add these helper methods for status colors
  Color _getPaymentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'on_the_way':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Add this method to show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              const Text('Filter Orders'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone dropdown
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                    color: Colors.blue.shade50,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedZone,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade800),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(8),
                      hint: Text(
                        'Select Zone',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.filter_none, 
                                size: 18, 
                                color: Colors.blue.shade800
                              ),
                              const SizedBox(width: 8),
                              const Text('All Zones'),
                            ],
                          ),
                        ),
                        ..._zones.map((zone) => DropdownMenuItem<String>(
                          value: zone['zoneId'].toString(),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, 
                                size: 18, 
                                color: Colors.blue.shade800
                              ),
                              const SizedBox(width: 8),
                              Text('Zone ${zone['zoneId']}'),
                            ],
                          ),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedZone = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date range selection
                Text(
                  'Date Range',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                          color: Colors.blue.shade50,
                        ),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12, 
                              horizontal: 8
                            ),
                          ),
                          icon: Icon(Icons.calendar_today, 
                            size: 18,
                            color: Colors.blue.shade800,
                          ),
                          label: Text(
                            _selectedFromDate == null
                                ? 'From'
                                : '${_selectedFromDate!.day}/${_selectedFromDate!.month}',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedFromDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedFromDate = date);
                            }
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, 
                        size: 16,
                        color: Colors.blue.shade400,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                          color: Colors.blue.shade50,
                        ),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12, 
                              horizontal: 8
                            ),
                          ),
                          icon: Icon(Icons.calendar_today, 
                            size: 18,
                            color: Colors.blue.shade800,
                          ),
                          label: Text(
                            _selectedToDate == null
                                ? 'To'
                                : '${_selectedToDate!.day}/${_selectedToDate!.month}',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedToDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedToDate = date);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedZone = null;
                  _selectedFromDate = null;
                  _selectedToDate = null;
                });
                Navigator.pop(context);
                super.setState(() {});
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                super.setState(() {});
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                minimumSize: const Size(88, 36),
              ),
              child: const Text('Apply'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        ),
      ),
    );
  }
}
