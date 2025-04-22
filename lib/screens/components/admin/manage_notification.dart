import 'package:flutter/material.dart';

import '../../../service/api_service.dart';

class ManageNotificationScreen extends StatefulWidget {
  const ManageNotificationScreen({Key? key}) : super(key: key);

  @override
  State<ManageNotificationScreen> createState() =>
      _ManageNotificationScreenState();
}

class _ManageNotificationScreenState extends State<ManageNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers for create notification form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Store notifications
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String _selectedRole = 'all'; // For targeting specific user roles

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    await _apiService.initializeAuthToken();
    await _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Initialize auth token and fetch notifications
      await _apiService.initializeAuthToken();
      final result = await _apiService.getAllNotifications();
      
      if (result['success']) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(result['notifications']);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Initialize auth token
      await _apiService.initializeAuthToken();

      // Call the API to create notification
      final result = await _apiService.createNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Notification sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reset form
        _formKey.currentState!.reset();
        _titleController.clear();
        _messageController.clear();

        // Refresh notifications list
        await _fetchNotifications();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send notification'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Notifications',
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
              indicatorColor: Colors.orange.shade400,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.notifications,
                    color: Colors.orange.shade300,
                  ),
                  text: 'View Notifications',
                ),
                Tab(
                  icon: Icon(Icons.add_alert, color: Colors.green.shade300),
                  text: 'Create Notification',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildViewNotificationsTab(), _buildCreateNotificationTab()],
      ),
    );
  }

  Widget _buildViewNotificationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
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
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  offset: const Offset(0, 4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade200.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: Colors.blue.shade800,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['message'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (notification['formattedExpiresAt'] != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires: ${notification['formattedExpiresAt']['date']} ${notification['formattedExpiresAt']['time']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.send, size: 16),
                              label: const Text(
                                'Trigger',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
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
        },
      ),
    );
  }

  Widget _buildCreateNotificationTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Create New Notification',
                Icons.notification_add,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Notification Title*',
                  prefixIcon: Icon(Icons.title, color: Colors.blue.shade800),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Notification Message*',
                  prefixIcon: Icon(Icons.message, color: Colors.blue.shade800),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Message is required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createNotification,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Send Notification',
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade800, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }
}
