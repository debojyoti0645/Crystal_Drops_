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
    _tabController = TabController(length: 2, vsync: this);
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
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
            .toIso8601String();
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
    var pending = _allOrders.where((order) => 
      order['payStatus'] == 'completed' && 
      order['deliveryStatus'] == 'pending'
    ).toList();
    
    pending.sort((a, b) {
      DateTime dateA = DateTime.parse(_getDateString(a));
      DateTime dateB = DateTime.parse(_getDateString(b));
      return dateB.compareTo(dateA); // Most recent first
    });
    
    return pending;
  }

  List<dynamic> _getCompletedDeliveries() {
    var completed = _allOrders.where((order) => 
      order['payStatus'] == 'completed' && 
      order['deliveryStatus'] == 'delivered'
    ).toList();
    
    completed.sort((a, b) {
      DateTime dateA = DateTime.parse(_getDateString(a));
      DateTime dateB = DateTime.parse(_getDateString(b));
      return dateB.compareTo(dateA);
    });
    
    return completed;
  }

  List<dynamic> _filterAndSortOrders(List<dynamic> orders) {
    var filteredOrders = orders.where((order) {
      // Filter by zone if selected
      if (_selectedZone != null && _selectedZone!.isNotEmpty) {
        if (order['zone'] != _selectedZone) {
          return false;
        }
      }

      // Filter by date range if selected
      if (_selectedFromDate != null || _selectedToDate != null) {
        DateTime orderDate = DateTime.parse(_getDateString(order));

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

    // Sort by date (already implemented in _getPendingDeliveries and _getCompletedDeliveries)
    return filteredOrders;
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
                  icon: Icon(
                    Icons.done_all,
                    color: Colors.green.shade300,
                  ),
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
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
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
                      _buildDeliveryList(_filterAndSortOrders(_getPendingDeliveries())),
                      _buildDeliveryList(_filterAndSortOrders(_getCompletedDeliveries())),
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

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: orders[index]['deliveryStatus'] == 'delivered'
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: orders[index]['deliveryStatus'] == 'delivered'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    orders[index]['deliveryStatus'] == 'delivered'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: orders[index]['deliveryStatus'] == 'delivered'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    'Order \n#${orders[index]['orderId']}',
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
                      color: orders[index]['deliveryStatus'] == 'delivered'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      orders[index]['deliveryStatus'].toString().toUpperCase(),
                      style: TextStyle(
                        color: orders[index]['deliveryStatus'] == 'delivered'
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
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
                      Text(
                        'Customer ID: ${orders[index]['buyer']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Zone: ${orders[index]['zone'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        orders[index]['formattedAmount'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }
}