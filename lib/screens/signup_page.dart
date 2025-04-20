import 'package:flutter/material.dart';
import 'package:water_supply/screens/login_screen.dart';
import 'package:water_supply/service/api_service.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gramPanchayatController = TextEditingController();
  final TextEditingController blockNoController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController policeStationController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController sansadNameController = TextEditingController();
  final TextEditingController sansadNoController = TextEditingController();
  final TextEditingController mouzaNameController = TextEditingController();
  final TextEditingController jurisdListNoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  DateTime? selectedDate;
  String? selectedGender;
  String selectedDistrict = "North 24 Parganas";
  String? selectedRole;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _apiService.register(
        name: nameController.text,
        phoneNo: phoneController.text,
        role: selectedRole?.toLowerCase() ?? '',
        password: passwordController.text,
        fatherName: fatherNameController.text,
        address: {
          'gramPanchayat': gramPanchayatController.text,
          'blockNo': blockNoController.text,
          'village': villageController.text,
          'pinCode': pinCodeController.text,
          'district': selectedDistrict,
          'policeStation': policeStationController.text,
        },
        aadharNo: aadharController.text,
        dob: selectedDate?.toIso8601String() ?? '',
        gender: selectedGender?.toLowerCase() ?? '',
        sansadName: sansadNameController.text,
        sansadNo: sansadNoController.text,
        mouzaName: mouzaNameController.text,
        jurisdListNo: jurisdListNoController.text,
      );

      if (response['success'] == true) {
        final user = response['user'];
        await showSuccessDialog(user);
      } else {
        showError(response['message'] ?? "Registration failed");
      }
    } catch (e) {
      showError("Registration failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> showSuccessDialog(Map<String, dynamic> user) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Registration Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${user['name']}'),
              Text('Account ID: ${user['accountId']}'),
              Text('Role: ${user['role'].toString().toUpperCase()}'),
              SizedBox(height: 10),
              Text(
                'Your account is pending approval.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange[700],
                ),
              ),
              Text(
                'আপনার অ্যাকাউন্ট অনুমোদনের জন্য অপেক্ষা করছে।',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Proceed to Login'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? prefixText,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.blue[700],
                    ),
                    onPressed: onToggleVisibility,
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 60,
                          color: Colors.blue[700],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please fill in your details",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  _buildSectionTitle("Personal Information"),
                  _buildTextField(
                    controller: nameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? "Please enter your name"
                                : null,
                  ),
                  _buildTextField(
                    controller: fatherNameController,
                    label: "Father's Name",
                    icon: Icons.person,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? "Please enter father's name"
                                : null,
                  ),

                  _buildTextField(
                    controller: phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    prefixText: "+91 ",
                    validator:
                        (value) =>
                            value?.length != 10
                                ? "Enter valid 10-digit number"
                                : null,
                  ),

                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue[700]),
                            SizedBox(width: 12),
                            Text(
                              selectedDate != null
                                  ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                  : "Select Date of Birth",
                              style: TextStyle(
                                color:
                                    selectedDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue[700]),
                      decoration: InputDecoration(
                        labelText: "Gender",
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.blue[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                      items: ["Male", "Female", "Other"].map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(
                            gender,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedGender = value),
                      validator: (value) => value == null ? "Please select gender" : null,
                    ),
                  ),

                  _buildSectionTitle("Address Information"),

                  _buildTextField(
                    controller: gramPanchayatController,
                    label: "Gram Panchayat",
                    icon: Icons.location_city_outlined,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildTextField(
                    controller: blockNoController,
                    label: "Block No",
                    icon: Icons.grid_view,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildTextField(
                    controller: villageController,
                    label: "Village",
                    icon: Icons.home_outlined,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildTextField(
                    controller: pinCodeController,
                    label: "PIN Code",
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value?.length != 6 ? "Enter valid PIN code" : null,
                  ),

                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRole,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue[700]),
                      decoration: InputDecoration(
                        labelText: "Role",
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(Icons.work_outline, color: Colors.blue[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                      items: ["Customer", "Distributor", "Delivery"].map((role) {
                        return DropdownMenuItem<String>(
                          value: role.toLowerCase(),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedRole = value),
                      validator: (value) => value == null ? "Please select role" : null,
                    ),
                  ),

                  _buildTextField(
                    controller: aadharController,
                    label: "Aadhar Number",
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value?.length != 12
                                ? "Enter valid 12-digit Aadhar"
                                : null,
                  ),

                  _buildSectionTitle("Additional Information"),

                  _buildTextField(
                    controller: sansadNameController,
                    label: "Sansad Name",
                    icon: Icons.business_outlined,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildTextField(
                    controller: sansadNoController,
                    label: "Sansad Number",
                    icon: Icons.numbers_outlined,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildTextField(
                    controller: mouzaNameController,
                    label: "Mouza Name",
                    icon: Icons.location_on_outlined,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildTextField(
                    controller: jurisdListNoController,
                    label: "Jurisd List No",
                    icon: Icons.list_alt_outlined,
                    validator:
                        (value) => value?.isEmpty ?? true ? "Required" : null,
                  ),

                  _buildSectionTitle("Security"),

                  _buildTextField(
                    controller: passwordController,
                    label: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                    validator:
                        (value) =>
                            (value?.length ?? 0) < 6
                                ? "Password too short"
                                : null,
                  ),

                  _buildTextField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                    validator:
                        (value) =>
                            value != passwordController.text
                                ? "Passwords don't match"
                                : null,
                  ),

                  SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child:
                            isLoading
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
