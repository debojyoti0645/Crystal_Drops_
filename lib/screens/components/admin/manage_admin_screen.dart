import 'package:flutter/material.dart';

import '../../../service/api_service.dart';

class ManageAdminScreen extends StatefulWidget {
  const ManageAdminScreen({Key? key}) : super(key: key);

  @override
  State<ManageAdminScreen> createState() => _ManageAdminScreenState();
}

class _ManageAdminScreenState extends State<ManageAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _sansadNameController = TextEditingController();
  final TextEditingController _sansadNoController = TextEditingController();
  final TextEditingController _mouzaNameController = TextEditingController();
  final TextEditingController _jurisdListNoController = TextEditingController();

  // Address fields
  final TextEditingController _gramPanchayatController =
      TextEditingController();
  final TextEditingController _blockNoController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _policeStationController =
      TextEditingController();

  String _selectedGender = 'male';
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAuthAndFetchData();
  }

  Future<void> _initializeAuthAndFetchData() async {
    // Initialize auth token first
    await _apiService.initializeAuthToken();
    // Then fetch data
    await _fetchAdmins();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _fatherNameController.dispose();
    _aadharController.dispose();
    _dobController.dispose();
    _sansadNameController.dispose();
    _sansadNoController.dispose();
    _mouzaNameController.dispose();
    _jurisdListNoController.dispose();
    _gramPanchayatController.dispose();
    _blockNoController.dispose();
    _villageController.dispose();
    _pinCodeController.dispose();
    _districtController.dispose();
    _policeStationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);

    try {
      // Check if token is available
      final token = _apiService.getAuthToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Authentication token not found. Please login again.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final result = await _apiService.getApprovedAccounts();

      if (result['success']) {
        // Filter only admin accounts
        final List<dynamic> allAccounts =
            result['data'] ??
            []; // Note: changed from result['accounts'] to result['data']
        final List<Map<String, dynamic>> adminAccounts =
            allAccounts
                .where((account) => account['role'] == 'admin')
                .map((account) {
                  // Convert createdAt timestamp to formatted date
                  String formattedDate = '';
                  if (account['createdAt'] != null) {
                    final seconds = account['createdAt']['_seconds'] as int;
                    final nanoseconds =
                        account['createdAt']['_nanoseconds'] as int;
                    final createdAtDateTime =
                        DateTime.fromMillisecondsSinceEpoch(
                          seconds * 1000 + (nanoseconds / 1000000).round(),
                        );
                    formattedDate =
                        '${createdAtDateTime.day}/${createdAtDateTime.month}/${createdAtDateTime.year}';
                  }

                  return {
                    'id': account['id'],
                    'name': account['name'],
                    'phoneNo': account['phoneNo'],
                    'accountId': account['accountId'],
                    'isConfirmed': account['isConfirmed'],
                    'createdAt': formattedDate,
                    'address': account['address'],
                    'zoneId': account['zoneId'] ?? 'Not Assigned',
                  };
                })
                .toList()
                .cast<Map<String, dynamic>>();

        setState(() {
          _admins = adminAccounts;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to fetch admins'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching admin accounts')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if token is available
    final token = _apiService.getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found. Please login again.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.createAdmin(
        name: _nameController.text,
        phoneNo: _phoneController.text,
        password: _passwordController.text,
        fatherName: _fatherNameController.text,
        address: {
          'gramPanchayat': _gramPanchayatController.text,
          'blockNo': _blockNoController.text,
          'village': _villageController.text,
          'pinCode': _pinCodeController.text,
          'district': _districtController.text,
          'policeStation': _policeStationController.text,
        },
        aadharNo: _aadharController.text,
        dob: _dobController.text,
        gender: _selectedGender,
        sansadName: _sansadNameController.text,
        sansadNo: _sansadNoController.text,
        mouzaName: _mouzaNameController.text,
        jurisdListNo: _jurisdListNoController.text,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin created successfully')),
        );
        _formKey.currentState!.reset();
        // Refresh the admin list
        await _fetchAdmins();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create admin'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating admin: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Admin Accounts',
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
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.orange.shade400,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              controller: _tabController,
              tabs: [
                Tab(
                  icon: Icon(Icons.people_alt, color: Colors.orange.shade300),
                  text: 'View Admins',
                ),
                Tab(
                  icon: Icon(Icons.person_add, color: Colors.green.shade300),
                  text: 'Create Admin',
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
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child:
            _isLoading
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
                        'Loading admins...',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : TabBarView(
                  controller: _tabController,
                  children: [_buildViewAdminsTab(), _buildCreateAdminTab()],
                ),
      ),
    );
  }

  Widget _buildViewAdminsTab() {
    if (_admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'No admin accounts found',
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
      onRefresh: _fetchAdmins,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _admins.length,
        itemBuilder: (context, index) {
          final admin = _admins[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade100, width: 1),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        admin['name'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            admin['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: ${admin['accountId']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            admin['isConfirmed']
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              admin['isConfirmed']
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                      child: Text(
                        admin['isConfirmed'] ? 'Active' : 'Pending',
                        style: TextStyle(
                          color:
                              admin['isConfirmed']
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow('Phone', admin['phoneNo'], Icons.phone),
                        _buildInfoRow(
                          'Created',
                          admin['createdAt'],
                          Icons.calendar_today,
                        ),
                        _buildInfoRow(
                          'Zone',
                          admin['zoneId'],
                          Icons.location_on,
                        ),
                        _buildInfoRow(
                          'District',
                          admin['address']['district'],
                          Icons.location_city,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAdminTab() {
    return Container(
      margin: const EdgeInsets.all(8),
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
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fatherNameController,
                label: 'Father\'s Name',
                prefixIcon: Icons.family_restroom,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Father\'s name is required'
                            : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      prefixIcon: Icons.calendar_today,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true ? 'DOB is required' : null,
                      readOnly: true, // Make the field read-only
                      onTap:
                          () => _selectDate(context), // Show date picker on tap
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedGender,
                      label: 'Gender',
                      prefixIcon: Icons.wc,
                      items: ['male', 'female', 'other'],
                      onChanged: (String? value) {
                        setState(() => _selectedGender = value ?? 'male');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _aadharController,
                label: 'Aadhar Number',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
                maxLength: 12,
                validator:
                    (value) =>
                        value?.length != 12
                            ? 'Enter valid 12-digit Aadhar number'
                            : null,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Contact Information', Icons.contact_phone),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                prefixText: '+91 ',
                validator:
                    (value) =>
                        value?.length != 10
                            ? 'Enter valid 10-digit phone number'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator:
                    (value) =>
                        (value?.length ?? 0) < 6
                            ? 'Password must be at least 6 characters'
                            : null,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Address Details', Icons.location_on),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _gramPanchayatController,
                label: 'Gram Panchayat',
                prefixIcon: Icons.location_city,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Gram Panchayat is required'
                            : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _blockNoController,
                      label: 'Block No',
                      prefixIcon: Icons.grid_view,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Block No is required'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _villageController,
                      label: 'Village',
                      prefixIcon: Icons.home_work,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Village is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pinCodeController,
                      label: 'PIN Code',
                      prefixIcon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator:
                          (value) =>
                              value?.length != 6
                                  ? 'Enter valid 6-digit PIN code'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _districtController,
                      label: 'District',
                      prefixIcon: Icons.location_city,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'District is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _policeStationController,
                label: 'Police Station',
                prefixIcon: Icons.local_police,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Police Station is required'
                            : null,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader(
                'Jurisdiction Details',
                Icons.account_balance,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sansadNameController,
                      label: 'Sansad Name',
                      prefixIcon: Icons.architecture,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Sansad Name is required'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _sansadNoController,
                      label: 'Sansad No',
                      prefixIcon: Icons.format_list_numbered,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Sansad No is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _mouzaNameController,
                      label: 'Mouza Name',
                      prefixIcon: Icons.map,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Mouza Name is required'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _jurisdListNoController,
                      label: 'Jurisd. List No',
                      prefixIcon: Icons.format_list_numbered,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Jurisd. List No is required'
                                  : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createAdmin,
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
                            'Create Admin Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? prefixText,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: '$label*',
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(prefixIcon, color: Colors.blue.shade800),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.1),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData prefixIcon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        // reduce the size of the label
        labelStyle: TextStyle(fontSize: 14, color: Colors.blue.shade800),
        labelText: '$label*',
        prefixIcon: Icon(prefixIcon, color: Colors.blue.shade800),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.1),
      ),
      items:
          items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item.toUpperCase()),
            );
          }).toList(),
      onChanged: onChanged,
    );
  }

  // Add this helper method for date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format the date as DD/MM/YY
      String formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year.toString().substring(2)}";
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }
}
