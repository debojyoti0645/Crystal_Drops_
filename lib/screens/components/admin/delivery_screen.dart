import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String? _error;
  bool _isDisposed = false;
  String? _selectedZone;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  List<dynamic> _zones = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
    _loadZones();
  }

  Future<void> _fetchOrders() async {
    if (_isDisposed || !mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _apiService.initializeAuthToken();
      final response = await _apiService.getAllOrders();

      if (_isDisposed || !mounted) return;

      if (response['success']) {
        setState(() {
          _allOrders = response['orders'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;

      setState(() {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadZones() async {
    try {
      await _apiService.initializeAuthToken();
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

  String _getDateString(dynamic order) {
    try {
      // Handle Firestore timestamp format
      if (order['createdAt'] != null &&
          order['createdAt']['_seconds'] != null) {
        int seconds = order['createdAt']['_seconds'];
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
        ).toIso8601String();
      }

      // Handle formatted date if available
      if (order['formattedCreatedAt'] != null) {
        return order['formattedCreatedAt']['fullDate'].toString();
      }

      // Handle string date
      if (order['createdAt'] is String) {
        return order['createdAt'];
      }

      return DateTime.now().toIso8601String(); // fallback
    } catch (e) {
      return DateTime.now().toIso8601String(); // fallback
    }
  }

  List<dynamic> _getPendingDeliveries() {
    var pending =
        _allOrders
            .where((order) => order['deliveryStatus'] == 'pending')
            .toList();

    pending.sort((a, b) {
      DateTime dateA = DateTime.parse(_getDateString(a));
      DateTime dateB = DateTime.parse(_getDateString(b));
      return dateB.compareTo(dateA); // Most recent first
    });

    return pending;
  }

  List<dynamic> _getCompletedDeliveries() {
    var completed =
        _allOrders
            .where(
              (order) =>
                  order['payStatus'] == 'completed' &&
                  order['deliveryStatus'] == 'delivered',
            )
            .toList();

    completed.sort((a, b) {
      DateTime dateA = DateTime.parse(_getDateString(a));
      DateTime dateB = DateTime.parse(_getDateString(b));
      return dateB.compareTo(dateA);
    });

    return completed;
  }

  List<dynamic> _getFailedDeliveries() {
    var failed =
        _allOrders
            .where(
              (order) =>
                  order['payStatus'] == 'completed' &&
                  order['deliveryStatus'] == 'failed',
            )
            .toList();

    failed.sort((a, b) {
      DateTime dateA = DateTime.parse(_getDateString(a));
      DateTime dateB = DateTime.parse(_getDateString(b));
      return dateB.compareTo(dateA); // Most recent first
    });

    return failed;
  }

  List<dynamic> _filterAndSortOrders(List<dynamic> orders) {
    var filteredOrders =
        orders.where((order) {
          // Filter by zone if selected
          if (_selectedZone != null && _selectedZone!.isNotEmpty) {
            if (order['zone'] != _selectedZone) {
              return false;
            }
          }

          // Filter by date range if selected
          if (_selectedFromDate != null || _selectedToDate != null) {
            DateTime orderDate = DateTime.parse(_getDateString(order));

            if (_selectedFromDate != null &&
                orderDate.isBefore(_selectedFromDate!)) {
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

    // Sort by date (already implemented in _getPendingDeliveries and _getCompletedDeliveries)
    return filteredOrders;
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
          'Delivery Tracking',
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
                    Icons.local_shipping,
                    color: Colors.orange.shade300,
                  ),
                  text: 'Pending',
                ),
                Tab(
                  icon: Icon(Icons.done_all, color: Colors.green.shade300),
                  text: 'Completed',
                ),
                Tab(
                  icon: Icon(Icons.error_outline, color: Colors.red.shade300),
                  text: 'Failed',
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
                        'Loading deliveries...',
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
                      ElevatedButton(
                        onPressed: _fetchOrders,
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
                    _buildDeliveryList(
                      _filterAndSortOrders(_getPendingDeliveries()),
                    ),
                    _buildDeliveryList(
                      _filterAndSortOrders(_getCompletedDeliveries()),
                    ),
                    _buildDeliveryList(
                      _filterAndSortOrders(_getFailedDeliveries()),
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

  Widget _buildDeliveryList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'No deliveries found',
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

    final Map<String, List<dynamic>> groupedOrders = {};

    for (var order in orders) {
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
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
              ...groupOrders.map((order) {
                final orderDateTime = DateTime.fromMillisecondsSinceEpoch(
                  order['createdAt']['_seconds'] * 1000,
                );
                
                // Format date and time with proper padding
                final dateString = 
                  '${orderDateTime.day.toString().padLeft(2, '0')}/${orderDateTime.month.toString().padLeft(2, '0')}/${orderDateTime.year}';
                final timeString = 
                  '${orderDateTime.hour.toString().padLeft(2, '0')}:${orderDateTime.minute.toString().padLeft(2, '0')}';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: order['deliveryStatus'] == 'delivered'
                            ? Colors.green.withOpacity(0.3)
                            : order['deliveryStatus'] == 'failed'
                                ? Colors.red.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header with Order ID and Status
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: order['deliveryStatus'] == 'delivered'
                                ? Colors.green.withOpacity(0.05)
                                : order['deliveryStatus'] == 'failed'
                                    ? Colors.red.withOpacity(0.05)
                                    : Colors.orange.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: order['deliveryStatus'] == 'delivered'
                                        ? Colors.green.withOpacity(0.3)
                                        : order['deliveryStatus'] == 'failed'
                                            ? Colors.red.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  order['deliveryStatus'] == 'delivered'
                                      ? Icons.check_circle
                                      : order['deliveryStatus'] == 'failed'
                                          ? Icons.error_outline
                                          : Icons.pending,
                                  color: order['deliveryStatus'] == 'delivered'
                                      ? Colors.green
                                      : order['deliveryStatus'] == 'failed'
                                          ? Colors.red
                                          : Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order['orderId']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order['deliveryStatus']?.toString().toUpperCase() ?? 'N/A'}',
                                      style: TextStyle(
                                        color: order['deliveryStatus'] == 'delivered'
                                            ? Colors.green
                                            : order['deliveryStatus'] == 'failed'
                                                ? Colors.red
                                                : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Text(
                                  '₹${order['totalAmount']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Order Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Customer Info
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Customer',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${order['buyerName']} (ID: ${order['buyer']})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Zone Info
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delivery Zone',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Zone ${order['zone'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Date and Time
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order Date & Time',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '$dateString at $timeString',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      const Text('Filter Deliveries'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Zone Filter - Redesigned
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
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.blue.shade800,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                                      Icon(
                                        Icons.filter_none,
                                        size: 18,
                                        color: Colors.blue.shade800,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('All Zones'),
                                    ],
                                  ),
                                ),
                                ..._zones
                                    .map(
                                      (zone) => DropdownMenuItem<String>(
                                        value: zone['zoneId'].toString(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 18,
                                              color: Colors.blue.shade800,
                                            ),
                                            const SizedBox(width: 8),
                                            Text('Zone ${zone['zoneId']}'),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedZone = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date Range - Minimalist Design
                        Text(
                          'Select Date Range',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                  ),
                                  color: Colors.blue.shade50,
                                ),
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Colors.blue.shade800,
                                  ),
                                  label: Text(
                                    _selectedFromDate == null
                                        ? 'From'
                                        : '${_selectedFromDate!.day}/${_selectedFromDate!.month}',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _selectedFromDate ?? DateTime.now(),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.blue.shade400,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                  ),
                                  color: Colors.blue.shade50,
                                ),
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Colors.blue.shade800,
                                  ),
                                  label: Text(
                                    _selectedToDate == null
                                        ? 'To'
                                        : '${_selectedToDate!.day}/${_selectedToDate!.month}',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _selectedToDate ?? DateTime.now(),
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

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }
}
