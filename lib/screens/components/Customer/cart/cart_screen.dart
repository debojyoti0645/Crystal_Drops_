import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:water_supply/screens/components/Customer/customer_home_screen.dart';
import 'package:water_supply/service/api_service.dart';

import 'cart.dart';

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
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

  Widget _buildPaymentOption(
    BuildContext context,
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

  Future<void> _handleProceedToPayment(CartProvider cart) async {
    setState(() => _isLoading = true);

    try {
      await _apiService.initializeAuthToken();

      List<String> productIds = cart.items.keys.toList();
      int totalQuantity = cart.items.values.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

      final response = await _apiService.createOrder(
        productIds: productIds,
        quantity: totalQuantity,
        totalAmount: cart.totalAmount.toString(),
      );

      if (!mounted) return;

      if (response['success']) {
        _currentOrderId = response['order']['id'];
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder:
              (ctx) => Container(
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
                            context,
                            'Pay with Cash',
                            Icons.money,
                            Colors.green,
                            () {
                              Navigator.pop(ctx);
                              _handleCashPayment(cart);
                            },
                          ),
                          SizedBox(height: 12),
                          _buildPaymentOption(
                            context,
                            'Pay Online',
                            Icons.payment,
                            Color(0xFF007BFF),
                            () {
                              Navigator.pop(ctx);
                              _handleOnlinePayment(cart);
                            },
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  void _handleCashPayment(CartProvider cart) async {
    try {
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'pending',
      );

      cart.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Pay on delivery.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleOnlinePayment(CartProvider cart) async {
    try {
      // First update payment status to pending
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'pending',
      );

      // Get user profile
      final userProfileResponse = await _apiService.getUserProfile();
      debugPrint('User Profile Response: $userProfileResponse'); // Debug print

      if (userProfileResponse['success'] && 
          userProfileResponse['user'] != null) {
        final userData = userProfileResponse['user'];
        
        var options = {
          'key': 'rzp_test_7XcuXcLBa3FCdM',
          'amount': (cart.totalAmount * 100).toInt(),
          'name': 'Crystal Drops',
          'description': 'Order Payment',
          'prefill': {
            'contact': userData['phoneNo'] ?? '', // Get phone directly from response
            'email': userData['accountId'] ?? '',  // Get email directly from response
          },
          'theme': {'color': '#007BFF'},
          'retry': {'enabled': true, 'max_count': 1},
          'modal': {'confirm_close': true, 'animation': true},
        };

        _razorpay.open(options);
      } else {
        throw Exception('Failed to get user profile data');
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        (route) => false,
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _apiService.updatePaymentStatus(
        orderId: _currentOrderId,
        paymentStatus: 'completed',
      );

      if (!mounted) return;

      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Successful!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating payment status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        (route) => false,
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating payment status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
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
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
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
        elevation: 0,
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
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF007BFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  cart.items.isEmpty ? _buildEmptyCart() : _buildCartList(cart),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(cart),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Start adding some items to your cart!',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(CartProvider cart) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final cartItem = cart.items.values.toList()[i];
        return Dismissible(
          key: ValueKey(cart.items.keys.toList()[i]),
          background: Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[300]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            cart.removeItem(cart.items.keys.toList()[i]);
          },
          child: _buildCartItem(cart, cartItem, i),
        );
      },
    );
  }

  Widget _buildCartItem(CartProvider cart, CartItem cartItem, int index) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '${cartItem.quantity}x',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007BFF),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          _buildCartItemDetails(cartItem),
          _buildCartItemActions(cart, cartItem, index),
        ],
      ),
    );
  }

  Widget _buildCartItemDetails(CartItem cartItem) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cartItem.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '₹${cartItem.price}',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemActions(
    CartProvider cart,
    CartItem cartItem,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${(cartItem.price * cartItem.quantity)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF007BFF),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            if (cartItem.quantity > 1)
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                onPressed: () => _showRemoveItemDialog(cart, cartItem, index),
              )
            else
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                onPressed: () {
                  cart.removeItem(cart.items.keys.toList()[index]);
                },
              ),
          ],
        ),
      ],
    );
  }

  void _showRemoveItemDialog(CartProvider cart, CartItem cartItem, int index) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Remove Items'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How many items do you want to remove?'),
                SizedBox(height: 16),
                Container(
                  height: 150,
                  width: 100,
                  child: ListView.builder(
                    itemCount: cartItem.quantity,
                    itemBuilder: (context, i) {
                      return ListTile(
                        title: Text('${i + 1}'),
                        onTap: () {
                          cart.removeQuantity(
                            cart.items.keys.toList()[index],
                            i + 1,
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          backgroundColor: Color(0xFFFF6F00),
        ),
        onPressed:
            cart.items.isEmpty || _isLoading
                ? null
                : () => _handleProceedToPayment(cart),
        child:
            _isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
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
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
