import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

class CustomerPaymentHistory extends StatefulWidget {
  const CustomerPaymentHistory({super.key});

  @override
  State<CustomerPaymentHistory> createState() => _CustomerPaymentHistoryState();
}

class _CustomerPaymentHistoryState extends State<CustomerPaymentHistory> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.initializeAuthToken();
      final response = await _apiService.getUserOrders();

      if (response['success']) {
        final allOrders = List<Map<String, dynamic>>.from(response['orders']);
        
        // Filter payments based on status
        final filteredPayments = allOrders.where((order) {
          final hasPaymentStatus = order['payStatus'] != null;
          final createdAt = DateTime.fromMillisecondsSinceEpoch(
            order['createdAt']['_seconds'] * 1000
          );
          final now = DateTime.now();

          bool isInTimeRange = true;
          if (_selectedFilter == 'this_month') {
            isInTimeRange = createdAt.year == now.year && 
                           createdAt.month == now.month;
          } else if (_selectedFilter == 'last_month') {
            final lastMonth = now.month == 1 
                ? DateTime(now.year - 1, 12) 
                : DateTime(now.year, now.month - 1);
            isInTimeRange = createdAt.year == lastMonth.year && 
                           createdAt.month == lastMonth.month;
          }

          return hasPaymentStatus && isInTimeRange;
        }).toList();

        // Sort by date (most recent first)
        filteredPayments.sort((a, b) {
          return (b['createdAt']['_seconds'] as int)
              .compareTo(a['createdAt']['_seconds'] as int);
        });

        setState(() {
          _payments = filteredPayments;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPaymentStatusText(Map<String, dynamic> payment) {
    if (payment['payStatus'] == 'completed') {
      return 'Payment Completed';
    } else if (payment['payStatus'] == 'failed') {
      return 'Payment Failed';
    } else {
      return 'Payment Pending';
    }
  }

  Color _getPaymentStatusColor(Map<String, dynamic> payment) {
    if (payment['payStatus'] == 'completed') {
      return Colors.green[700]!;
    } else if (payment['payStatus'] == 'failed') {
      return Colors.red[700]!;
    } else {
      return Colors.orange[700]!;
    }
  }

  String _formatDate(int seconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
              _loadPaymentHistory();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Time')),
              PopupMenuItem(value: 'this_month', child: Text('This Month')),
              PopupMenuItem(value: 'last_month', child: Text('Last Month')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadPaymentHistory,
          color: Color(0xFF007BFF),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF007BFF)),
                )
              : _payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No completed transactions',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.white, Color(0xFFE3F2FD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        payment['payStatus'] == 'completed'
                                            ? Icons.check_circle
                                            : payment['payStatus'] == 'failed'
                                                ? Icons.cancel
                                                : Icons.pending,
                                        color: _getPaymentStatusColor(payment),
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Order #${payment['orderId']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatDate(payment['createdAt']['_seconds']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPaymentStatusText(payment),
                                      style: TextStyle(
                                        color: _getPaymentStatusColor(payment),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Delivery: ${payment['deliveryStatus']?.toUpperCase() ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF007BFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${payment['totalAmount']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF007BFF),
                                  ),
                                ),
                              ),
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
