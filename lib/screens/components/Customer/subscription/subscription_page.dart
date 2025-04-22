import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_supply/service/api_service.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key});

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  String? accountId;
  String? name;
  String? phoneNumber;
  String? address;
  bool wantBottomJar = false;
  String selectedJarSize = '10L';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  List<Map<String, dynamic>> connectionTypes = [];
  bool _isLoadingTypes = true;
  Map<String, dynamic>? selectedConnectionType;

  late Razorpay _razorpay;
  String _currentConnectionId = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoadingTypes = true);
    
    // First initialize the API service
    await _initializeApiService();
    
    // Then load user details and connection types
    await Future.wait([
      _loadUserDetails(),
      _loadConnectionTypes(),
    ]);
    
    setState(() => _isLoadingTypes = false);
  }

  // Add this new method to initialize the API service
  Future<void> _initializeApiService() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      
      if (token != null) {
        _apiService.setAuthToken(token);
        debugPrint('Auth token initialized: $token');
      } else {
        debugPrint('No auth token found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error initializing API service: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');
      final String? token = prefs.getString('token');

      if (userDataString != null) {
        final Map<String, dynamic> userData = json.decode(userDataString);
        setState(() {
          accountId = userData['accountId'];
          name = userData['name'];
          phoneNumber = userData['phoneNumber'];
          address = userData['address'];
        });

        nameController.text = name ?? '';
        phoneController.text = accountId ?? '';
      }

      // Set the auth token in ApiService if available
      if (token != null) {
        _apiService.setAuthToken(token);
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  // Add this new method to load connection types
  Future<void> _loadConnectionTypes() async {
    try {
      if (_apiService.getAuthToken() == null) {
        debugPrint('No auth token available. Attempting to reinitialize...');
        await _initializeApiService();
        
        if (_apiService.getAuthToken() == null) {
          _showError('Authentication token not available. Please login again.');
          return;
        }
      }

      final result = await _apiService.getAllConnectionTypes();
      if (result['success']) {
        // Changed from 'connectionTypes' to 'connections' to match API response
        setState(() {
          connectionTypes = List<Map<String, dynamic>>.from(result['connections'] ?? []);
          debugPrint('Loaded ${connectionTypes.length} connection types');
          
          // Set default selected type if available
          if (connectionTypes.isNotEmpty) {
            selectedConnectionType = connectionTypes.firstWhere(
              (type) => type['water_container'] == selectedJarSize,
              orElse: () => connectionTypes.first,
            );
            debugPrint('Selected connection type: ${selectedConnectionType?['name']}');
          }
        });
      } else {
        _showError(result['message'] ?? 'Failed to load connection types');
      }
    } catch (e) {
      debugPrint('Error loading connection types: $e');
      _showError('Failed to load connection types. Please try again later.');
    }
  }

  // Add this helper method for showing errors
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (selectedConnectionType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a connection type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authToken = _apiService.getAuthToken();
      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await _apiService.createConnection(
        connectionTypeId: selectedConnectionType!['connectionTypeId'],
        waterTapNeeded: wantBottomJar,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while creating subscription'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // First, add this method above the build method:
  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title: const Text('Pay Online'),
                subtitle: const Text('Pay now using UPI, Card, or Net Banking'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _processOnlinePayment();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text('Pay at Office'),
                subtitle: const Text('Visit our office to complete the payment'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _processCashPayment();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Update these methods:
  void _processOnlinePayment() async {
    try {
      setState(() => _isLoading = true);
      
      // First create the connection
      final connectionResult = await _apiService.createConnection(
        connectionTypeId: selectedConnectionType!['connectionTypeId'],
        waterTapNeeded: wantBottomJar,
      );

      if (!connectionResult['success']) {
        _showError(connectionResult['message'] ?? 'Failed to create connection');
        return;
      }

      // Get user profile for payment details
      final userProfileResponse = await _apiService.getUserProfile();
      debugPrint('User Profile Response: $userProfileResponse');

      if (userProfileResponse['success'] && userProfileResponse['user'] != null) {
        final userData = userProfileResponse['user'];
        final connectionId = connectionResult['connection']['connectionId'];
        final totalAmount = _calculateTotalAmount();

        var options = {
          'key': 'rzp_test_anTvhnaW9Kw7kN', // Replace with your Razorpay key
          'amount': (totalAmount * 100).toInt(), // Amount in smallest currency unit
          'name': 'Crystal Drops',
          'description': 'Connection Subscription Payment',
          'prefill': {
            'contact': userData['phoneNo'] ?? '',
            'email': userData['accountId'] ?? '',
          },
          'theme': {'color': '#007BFF'},
          'retry': {'enabled': true, 'max_count': 1},
          'modal': {'confirm_close': true, 'animation': true},
        };

        _razorpay.open(options);
        
        // Store connection ID for use in payment handlers
        setState(() {
          _currentConnectionId = connectionId;
        });
      } else {
        throw Exception('Failed to get user profile data');
      }
    } catch (e) {
      debugPrint('Error in online payment process: $e');
      _showError('An error occurred during payment process');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processCashPayment() async {
    try {
      setState(() => _isLoading = true);
      
      // Create connection for office payment
      final result = await _apiService.createConnection(
        connectionTypeId: selectedConnectionType!['connectionTypeId'],
        waterTapNeeded: wantBottomJar,
      );

      if (result['success']) {
        // Extract connection details from the response
        final connectionData = result['connection'] as Map<String, dynamic>;
        final connectionId = connectionData['connectionId'] ?? 'N/A';

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Payment Instructions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please visit our office to complete the payment:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Amount to Pay: ₹${_calculateTotalAmount()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connection ID: $connectionId',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Office Address:\n'
                    '123 Main Street\n'
                    'City, State\n'
                    'Working Hours: 9 AM - 6 PM',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Pop the subscription page
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        _showError(result['message'] ?? 'Failed to create subscription');
      }
    } catch (e) {
      debugPrint('Error in cash payment process: $e');
      _showError('An error occurred while processing your request');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add these methods to handle different payment options:


  double _calculateTotalAmount() {
    if (selectedConnectionType == null) return 0;
    
    final baseAmount = selectedConnectionType!['amount'] ?? 0;
    final regAmount = selectedConnectionType!['regAmount'] ?? 0;
    final waterTapCharges = wantBottomJar ? selectedConnectionType!['waterTapCharges'] ?? 0 : 0;
    
    return (baseAmount + regAmount + waterTapCharges).toDouble();
  }

  Future<void> _confirmOfflinePaymentRequest() async {
    // TODO: Implement API call to create subscription with offline payment method
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription request submitted for offline payment'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Activate the connection after successful payment
      final activationResult = await _apiService.activateConnection(_currentConnectionId);

      if (!mounted) return;

      if (activationResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Connection Activated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError('Payment successful but activation failed. Please contact support.');
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error in payment success handler: $e');
      _showError('Payment successful but activation failed. Please contact support.');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    _showError('Payment Failed: ${response.message ?? 'Error occurred'}');
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear event handlers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add this check at the start of build
    if (_apiService.getAuthToken() == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscribe Now')),
        body: const Center(
          child: Text(
            'Please login to view subscription options',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscribe Now',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.blue.withOpacity(0.5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJarSelectionCards(),
                        const SizedBox(height: 20),
                        _buildSubscriptionDetails(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: wantBottomJar,
                    onChanged: (bool? value) {
                      setState(() {
                        wantBottomJar = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    'Want a bottom jar?\nIt will cost ₹ 50 one time',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Bottom Jar Conditions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Adding a bottom jar to your subscription will incur a one-time cost of ₹ 50. This jar is reusable and must be returned in good condition upon cancellation of the subscription.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Your Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Account ID',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _isLoading ? null : _showPaymentOptions,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Request Subscription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJarSelectionCard(
    String size,
    String price,
    String title, {
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [const Color(0xFF007BFF), const Color(0xFF00C6FF)]
                  : [Colors.white, const Color(0xFFE3F2FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                size: 40,
                color: isSelected ? Colors.white : const Color(0xFF007BFF),
              ),
              const SizedBox(height: 4),
              Text(
                size,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJarSelectionCards() {
    if (_isLoadingTypes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (connectionTypes.isEmpty) {
      return const Center(
        child: Text(
          'No connection types available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: connectionTypes.map((type) {
        final isSelected = selectedConnectionType?['id'] == type['id'];
        final size = type['water_container'];
        final price = '₹${type['amount']}';
        final name = type['name'];

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _buildJarSelectionCard(
              size,
              price,
              name,
              onTap: () => setState(() {
                selectedConnectionType = type;
                selectedJarSize = size;
              }),
              isSelected: isSelected,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionDetails() {
    if (selectedConnectionType == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Please select a connection type above',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final baseAmount = selectedConnectionType!['amount'];
    final regAmount = selectedConnectionType!['regAmount'] ?? 0;
    final waterTapCharges = wantBottomJar ? selectedConnectionType!['waterTapCharges'] : 0;
    final totalAmount = baseAmount + regAmount + waterTapCharges;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedConnectionType!['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow('Container Size:', selectedConnectionType!['water_container']),
            _detailRow('Base Price:', '₹$baseAmount'),
            _detailRow('Registration Amount:', '₹$regAmount'),
            if (wantBottomJar)
              _detailRow('Water Tap Charges:', '₹$waterTapCharges'),
            const Divider(height: 24),
            _detailRow('Total Amount:', '₹$totalAmount',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (selectedConnectionType!['description'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedConnectionType!['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          Text(
            value,
            style: style ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
