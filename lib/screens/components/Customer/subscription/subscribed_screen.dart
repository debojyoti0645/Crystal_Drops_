import 'package:flutter/material.dart';

class SubscribedScreen extends StatefulWidget {
  Map<String, dynamic> connectionDetails;
  
  SubscribedScreen({
    super.key,
    required this.connectionDetails,
  });

  @override
  State<SubscribedScreen> createState() => _SubscribedScreenState();
}

class _SubscribedScreenState extends State<SubscribedScreen> {
  bool _isLoading = false;
  late final Map<String, dynamic> _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.connectionDetails['connection'];
  }

  Future<void> _loadSubscriptionData() async {
    // Simulate API loading
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _requestNewBottle() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bottle request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscription'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptionData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.blue.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Connection Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('Connection ID', _connection['connectionId']),
                              _buildInfoRow('Connection Type', _connection['connectionType']),
                              _buildInfoRow('Status', _connection['status']),
                              _buildInfoRow('Amount', _connection['amount'] != null ? '₹${_connection['amount']}' : 'N/A'),
                              _buildInfoRow('Due Amount', _connection['dueAmount'] != null ? '₹${_connection['dueAmount']}' : 'N/A'),
                              _buildInfoRow('Zone ID', _connection['zoneId']),
                              const Divider(height: 24),
                              const Text(
                                'Address',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('District', _connection['address']?['district']),
                              _buildInfoRow('Pin Code', _connection['address']?['pinCode']),
                              if (_connection['address']?['village']?.toString().isNotEmpty ?? false)
                                _buildInfoRow('Village', _connection['address']?['village']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _connection['status'].toLowerCase() == 'active' 
                              ? (_isLoading ? null : _requestNewBottle)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Request New Bottle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }
}