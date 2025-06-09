import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/screens/components/Distributer/distributor_home_screen.dart';
import 'package:water_supply/service/api_service.dart';

class DistributorPaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final double totalAmount;
  final int totalQuantity;

  const DistributorPaymentPage({
    super.key,
    required this.selectedItems,
    required this.totalAmount,
    required this.totalQuantity,
  });

  @override
  State<DistributorPaymentPage> createState() => _DistributorPaymentPageState();
}

class _DistributorPaymentPageState extends State<DistributorPaymentPage> {
  late Razorpay _razorpay;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _currentOrderId = '';

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  Future<void> _initializeApiService() async {
    await _apiService.initializeAuthToken();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (!mounted) return;

      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'completed',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Successful!'),
          backgroundColor: Colors.green,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('userData') ?? '{}');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => DistributorHomeScreen(
                distributorName: userData['name'] ?? '',
                distributorID: userData['accountId']?.toString() ?? '',
              ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'failed',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Failed: ${response.message ?? 'Error occurred'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleProceedToPayment(double totalAmount) async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.createOrder(
        productIds:
            widget.selectedItems.map((item) => item['id'].toString()).toList(),
        quantity: widget.totalQuantity,
        totalAmount: widget.totalAmount.toString(),
      );

      if (!mounted) return;

      if (response['success']) {
        _currentOrderId = response['order']['id'];
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _buildPaymentOptionsSheet(ctx),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to create order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPaymentOptionsSheet(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                _buildPaymentOption(
                  'Pay with Cash',
                  Icons.money,
                  Colors.green,
                  () {
                    Navigator.pop(ctx);
                    _handleCashPayment();
                  },
                ),
                SizedBox(height: 12),
                _buildPaymentOption(
                  'Pay Online',
                  Icons.payment,
                  Color(0xFF007BFF),
                  () {
                    Navigator.pop(ctx);
                    _handleOnlinePayment();
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCashPayment() async {
    try {
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'pending',
      );

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('userData') ?? '{}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Pay on delivery.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => DistributorHomeScreen(
                distributorName: userData['name'] ?? '',
                distributorID: userData['accountId']?.toString() ?? '',
              ),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleOnlinePayment() async {
    try {
      // First update payment status to pending
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'pending',
      );

      // Get user profile
      final userProfileResponse = await _apiService.getUserProfile();
      debugPrint('User Profile Response: ${jsonEncode(userProfileResponse)}');

      if (userProfileResponse['success'] == true &&
          userProfileResponse['user'] != null) {

        var options = {
          'key': 'rzp_test_7XcuXcLBa3FCdM	',
          'amount': (widget.totalAmount * 100).toInt(),
          'name': 'Crystal Drops',
          'description': 'Bulk Order Payment',
          'theme': {'color': '#007BFF'},
        };

        _razorpay.open(options);
      } else {
        throw Exception(
          'Failed to get user profile: ${userProfileResponse['message']}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Update payment status to failed
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'failed',
      );

      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('userData') ?? '{}');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => DistributorHomeScreen(
                distributorName: userData['name'] ?? '',
                distributorID: userData['accountId']?.toString() ?? '',
              ),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: widget.selectedItems.length,
                itemBuilder: (context, index) {
                  final item = widget.selectedItems[index];
                  return Card(
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.2),
                    margin: EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0xFFE3F2FD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'product-${item['id']}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item['imgUrl'] ?? '',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Color(0xFF007BFF),
                                          size: 32,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? 'Untitled',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Quantity: ${item['quantity']} units',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '₹${(item['amount'] * item['quantity']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00C853),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${widget.totalQuantity} units',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '₹${widget.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007BFF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () =>
                                    _handleProceedToPayment(widget.totalAmount),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF007BFF),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Color(0xFF007BFF).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Proceed to Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
