import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];

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
        final orders = List<Map<String, dynamic>>.from(response['orders']);
        setState(() {
          _payments = orders
              .where((order) => 
                  order['deliveryStatus'] == 'delivered' && 
                  order['payStatus'] == 'completed')
              .toList()
            ..sort((a, b) {
              final aTime = a['createdAt']['_seconds'] as int;
              final bTime = b['createdAt']['_seconds'] as int;
              return bTime.compareTo(aTime);
            });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load payments')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(Map<String, dynamic> timestamp) {
    final seconds = timestamp['_seconds'] as int;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(child: Text('No payment history available'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.payment, color: Colors.blue),
                        ),
                        title: Text(
                          'Order #${payment['orderId']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('Date: ${_formatDate(payment['createdAt'])}'),
                            Text('Zone: ${payment['zone']}'),
                            Text('Quantity: ${payment['quantity']}'),
                          ],
                        ),
                        trailing: Text(
                          '₹${payment['totalAmount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
