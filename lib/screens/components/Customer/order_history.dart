import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

class CustOrderSummary extends StatefulWidget {
  const CustOrderSummary({super.key});

  @override
  State<CustOrderSummary> createState() => _CustOrderSummaryState();
}

class _CustOrderSummaryState extends State<CustOrderSummary>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _errorMessage;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Map<String, List<dynamic>> _groupOrdersByDate(List<dynamic> orders) {
    final Map<String, List<dynamic>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    orders.sort((a, b) {
      final aDate = DateTime.parse(a['formattedCreatedAt']['timestamp']);
      final bDate = DateTime.parse(b['formattedCreatedAt']['timestamp']);
      return bDate.compareTo(aDate);
    });

    for (var order in orders) {
      if (order['formattedCreatedAt'] != null) {
        final orderDate = DateTime.parse(
          order['formattedCreatedAt']['timestamp'],
        );
        final orderDay = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
        );

        String dateKey;
        if (orderDay == today) {
          dateKey = 'Today';
        } else if (orderDay == today.subtract(const Duration(days: 1))) {
          dateKey = 'Yesterday';
        } else {
          // Format date as "DD MMM YYYY"
          dateKey =
              '${orderDate.day} ${_getMonthName(orderDate.month)} ${orderDate.year}';
        }

        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(order);
      }
    }

    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = screenWidth / 375;
    return baseSize * (scale < 1 ? 1 : (scale > 1.5 ? 1.5 : scale));
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      await _apiService.initializeAuthToken();
      final response = await _apiService.getUserOrders();

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

  List<dynamic> _getPendingDeliveryOrders() {
    return _orders.where((order) => 
      order['deliveryStatus'] == 'pending' &&
      (order['payStatus'] == 'completed' || order['payStatus'] == 'failed')
    ).toList();
  }

  List<dynamic> _getCashPaymentOrders() {
    return _orders.where((order) =>
      order['payStatus'] == 'pending' &&
      order['deliveryStatus'] == 'pending'
    ).toList();
  }

  List<dynamic> _getCompletedOrders() {
    return _orders.where((order) =>
      order['deliveryStatus'] == 'delivered' &&
      order['payStatus'] == 'completed'
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(getResponsiveHeight(context, 15)),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            'Order Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: getResponsiveFontSize(context, 22),
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(getResponsiveHeight(context, 6)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 2,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.orange.shade200,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: getResponsiveFontSize(context, 12),
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: getResponsiveFontSize(context, 12),
                ),
                tabs: _buildResponsiveTabs(context),
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
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadOrders,
          color: Color(0xFF007BFF),
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF007BFF)),
                  )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : SafeArea(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderList(
                          _getPendingDeliveryOrders(),
                          'Pending Delivery',
                        ),
                        _buildOrderList(
                          _getCashPaymentOrders(),
                          'Cash Payment',
                        ),
                        _buildOrderList(_getCompletedOrders(), 'Completed'),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  List<Widget> _buildResponsiveTabs(BuildContext context) {
    final double tabHeight = getResponsiveHeight(context, 6);
    final double iconSize = getResponsiveFontSize(context, 20);

    return [
      Tab(
        child: Container(
          height: tabHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions, size: iconSize),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Not Delivered',
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      Tab(
        child: Container(
          height: tabHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: iconSize),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Cash Payment',
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      Tab(
        child: Container(
          height: tabHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: iconSize),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Oops!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade300,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade300, fontSize: 16),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method inside the _CustOrderSummaryState class
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: getResponsiveFontSize(context, 64),
              color: Color(0xFF007BFF),
            ),
          ),
          SizedBox(height: getResponsiveHeight(context, 2)),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: Color(0xFF007BFF),
            ),
          ),
          SizedBox(height: getResponsiveHeight(context, 1)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getResponsiveWidth(context, 10),
            ),
            child: Text(
              'You haven\'t placed any orders in this category yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String title) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    final groupedOrders = _groupOrdersByDate(orders);

    return Container(
      padding: EdgeInsets.all(getResponsiveWidth(context, 4)),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: groupedOrders.keys.length,
        itemBuilder: (context, index) {
          final dateKey = groupedOrders.keys.elementAt(index);
          final dateOrders = groupedOrders[dateKey]!;

          if (dateOrders.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: getResponsiveHeight(context, 1),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: getResponsiveWidth(context, 4),
                  vertical: getResponsiveHeight(context, 1),
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF007BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    getResponsiveWidth(context, 2),
                  ),
                ),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007BFF),
                  ),
                ),
              ),
              ...dateOrders.map((order) => _buildOrderCard(order)).toList(),
            ],
          );
        },
      ),
    );
  }

  // First, add this helper method to format the timestamp
  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
        timestamp['_seconds'] * 1000,
      );
      
      // Format date
      final String date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      
      // Format time in 12-hour format with AM/PM
      final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final String time = 
          '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
      
      return '$date at $time';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Then modify the _buildOrderCard method to update the timestamp display
  Widget _buildOrderCard(dynamic order) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.only(bottom: getResponsiveHeight(context, 2)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getResponsiveWidth(context, 4)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(getResponsiveWidth(context, 4)),
        ),
        child: Padding(
          padding: EdgeInsets.all(getResponsiveWidth(context, 4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        color: Color(0xFF007BFF),
                        size: getResponsiveFontSize(context, 24),
                      ),
                      SizedBox(width: getResponsiveWidth(context, 2)),
                      Text(
                        "Order #${order['orderId']}",
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007BFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: getResponsiveHeight(context, 1)),
              // Add new timestamp row
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: getResponsiveFontSize(context, 16),
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: getResponsiveWidth(context, 2)),
                  Text(
                    _formatDateTime(order['createdAt']),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: getResponsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
              _buildOrderDetails(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(dynamic order) {
    return Column(
      children: [
        Divider(height: getResponsiveHeight(context, 3)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Status",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: getResponsiveFontSize(context, 12),
                  ),
                ),
                SizedBox(height: getResponsiveHeight(context, 0.5)),
                _buildStatusChip(order['payStatus']),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Amount",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: getResponsiveFontSize(context, 14),
                  ),
                ),
                SizedBox(height: getResponsiveHeight(context, 0.5)),
                Text(
                  "₹${order['totalAmount']}",
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007BFF),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: getResponsiveHeight(context, 2)),
        _buildStatusChip(order['deliveryStatus']),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveWidth(context, 3),
        vertical: getResponsiveHeight(context, 0.7),
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(getResponsiveWidth(context, 5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: getResponsiveFontSize(context, 16),
            color: _getStatusColor(status),
          ),
          SizedBox(width: getResponsiveWidth(context, 1)),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: getResponsiveFontSize(context, 10),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
