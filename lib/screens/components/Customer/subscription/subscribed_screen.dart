import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

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
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    await _apiService.initializeAuthToken();
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
                                'Subscription Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('Connection ID', 
                                widget.connectionDetails['connectionId']),
                              _buildInfoRow('Connection Type', 
                                widget.connectionDetails['connectionType']),
                              _buildInfoRow('Status', 
                                widget.connectionDetails['status']),
                              _buildInfoRow('Amount', 
                                '₹${widget.connectionDetails['amount']}'),
                              _buildInfoRow('Due Amount', 
                                '₹${widget.connectionDetails['dueAmount']}'),
                              _buildInfoRow('Water Tap', 
                                widget.connectionDetails['waterTapNeeded'] ? 'Yes' : 'No'),
                              _buildInfoRow('Created On', 
                                widget.connectionDetails['createdAt']['date']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: _requestNewBottle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Request New Bottle',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);
    
    final response = await _apiService.getUserConnectionDetails(
      widget.connectionDetails['id'],
    );

    setState(() {
      _isLoading = false;
      if (response['success'] && response['hasConnection']) {
        widget.connectionDetails = response['connectionDetails'];
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
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
            value,
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

  void _requestNewBottle() {
    if (!mounted) return;  // Add mounted check

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use a separate context
        return AlertDialog(
          title: const Text('Confirm Request'),
          content: const Text('Would you like to request a new water jar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                setState(() => _isLoading = true);

                try {
                  final ApiService apiService = ApiService();
                  await apiService.initializeAuthToken();
                  
                  final response = await apiService.requestNewJar(
                    widget.connectionDetails['connectionId'],
                  );

                  if (!mounted) return;

                  setState(() => _isLoading = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Request completed'),
                      backgroundColor: response['success'] == true ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Refresh data if request was successful
                  if (response['success'] == true) {
                    await _loadSubscriptionData();
                  }

                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to request new jar. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}