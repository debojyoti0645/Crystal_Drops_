import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String phoneNo;
  final String role;
  final String fatherName;
  final Map<String, String> address;
  final String aadharNo;
  final String dob;
  final String gender;
  final String sansadName;
  final String sansadNo;
  final String mouzaName;
  final String jurisdListNo;
  final String accountId;
  final bool isConfirmed;
  final String zoneId; // Added zoneId field

  UserProfile({
    required this.id,
    required this.name,
    required this.phoneNo,
    required this.role,
    required this.fatherName,
    required this.address,
    required this.aadharNo,
    required this.dob,
    required this.gender,
    required this.sansadName,
    required this.sansadNo,
    required this.mouzaName,
    required this.jurisdListNo,
    required this.accountId,
    required this.isConfirmed,
    required this.zoneId, // Added to constructor
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      role: json['role'] ?? '',
      fatherName: json['fatherName'] ?? '',
      address: Map<String, String>.from(json['address'] ?? {}),
      aadharNo: json['aadharNo'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      sansadName: json['sansadName'] ?? '',
      sansadNo: json['sansadNo'] ?? '',
      mouzaName: json['mouzaName'] ?? '',
      jurisdListNo: json['jurisdListNo'] ?? '',
      accountId: json['accountId'] ?? '',
      isConfirmed: json['isConfirmed'] ?? false,
      zoneId: json['zoneId'] ?? '', // Added to fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNo': phoneNo,
      'role': role,
      'fatherName': fatherName,
      'address': address,
      'aadharNo': aadharNo,
      'dob': dob,
      'gender': gender,
      'sansadName': sansadName,
      'sansadNo': sansadNo,
      'mouzaName': mouzaName,
      'jurisdListNo': jurisdListNo,
      'accountId': accountId,
      'isConfirmed': isConfirmed,
      'zoneId': zoneId, // Added to toJson
    };
  }
}

class ApiService {
  final String baseUrl = 'https://crystal-drop-backend.onrender.com/api/';
  String? _authToken;
  UserProfile? _userProfile;

  // Getter and setter for auth token
  String? get authToken => _authToken;
  set authToken(String? token) {
    _authToken = token;
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  String? getAuthToken() {
    return _authToken;
  }

  UserProfile? get userProfile => _userProfile;

  Future<void> initializeAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('token');
    debugPrint('Initialized auth token: $_authToken');
  }

  Future<Map<String, dynamic>> verifyUser(
    String token,
    String phoneNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'data': {'isConfirmed': false},
          'message': 'Verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': {'isConfirmed': false},
        'message': 'Network error',
      };
    }
  }

  // FUNCTION TO REGISTER A NEW USER
  Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNo,
    required String role,
    required String password,
    required String fatherName,
    required Map<String, String> address,
    required String aadharNo,
    required String dob,
    required String gender,
    required String sansadName,
    required String sansadNo,
    required String mouzaName,
    required String jurisdListNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'phoneNo': phoneNo,
          'role': role,
          'password': password,
          'fatherName': fatherName,
          'address': {
            'gramPanchayat': address['gramPanchayat'],
            'blockNo': address['blockNo'],
            'village': address['village'],
            'pinCode': address['pinCode'],
            'district': address['district'],
            'policeStation': address['policeStation'],
          },
          'aadharNo': aadharNo,
          'dob': dob,
          'gender': gender,
          'sansadName': sansadName,
          'sansadNo': sansadNo,
          'mouzaName': mouzaName,
          'jurisdListNo': jurisdListNo,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // FUNCTION TO LOGIN A USER
  Future<Map<String, dynamic>> login(
    String accountId,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountId': accountId,
          'password': password,
          'role': role,
        }),
      );

      final decodedResponse = json.decode(response.body);

      // Extract and store token if login is successful
      if (decodedResponse['success'] == true &&
          decodedResponse['token'] != null) {
        _authToken = decodedResponse['token'];
      }

      return {
        'success': decodedResponse['success'] ?? false,
        'token': decodedResponse['token'],
        'user': decodedResponse['user'],
        'message': decodedResponse['message'] ?? 'Unknown error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'token': null,
        'user': null,
        'message': 'Network error occurred',
      };
    }
  }

  // FUNCTION TO FETCH PENDING ACCOUNTS
  Future<Map<String, dynamic>> getPendingAccounts() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'data': [],
          'count': 0,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Calling API: ${baseUrl}admin/pending-accounts');

      final response = await http.get(
        Uri.parse('${baseUrl}admin/pending-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      // Debug: Print response status and body
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'],
          'data': decodedResponse['accounts'] ?? [],
          'count': decodedResponse['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'data': [],
          'count': 0,
          'message': 'Failed to fetch pending accounts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'count': 0,
        'message': 'Network error occurred',
      };
    }
  }

  // FUNCTION TO GET ALL APPROVED USERS
  Future<Map<String, dynamic>> getApprovedAccounts() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'data': [],
          'count': 0,
          'message': 'No authentication token available',
        };
      }

      final response = await http.get(
        Uri.parse('${baseUrl}admin/approved-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'],
          'data': decodedResponse['accounts'] ?? [],
          'count': decodedResponse['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'data': [],
          'count': 0,
          'message': 'Failed to fetch approved accounts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'count': 0,
        'message': 'Network error occurred',
      };
    }
  }

  // FUNCTION TO APPROVE AN ACCOUNT
  Future<Map<String, dynamic>> approveAccount(
    String userId,
    String role,
    String zoneId,
  ) async {
    try {
      if (_authToken == null) {
        debugPrint('Auth token is missing');
        return {'success': false, 'message': 'Authentication token is missing'};
      }

      debugPrint('Making API request to approve account...');
      debugPrint('Endpoint: ${baseUrl}admin/approve-account/$userId');
      debugPrint('User ID: $userId, Role: $role, Zone ID: $zoneId');

      final response = await http.put(
        Uri.parse('${baseUrl}admin/approve-account/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'userId': userId, 'role': role, 'zoneId': zoneId}),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse;
      } else {
        return {
          'success': false,
          'message': 'Server returned status code: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in approveAccount: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // FUNCTION TO REJECT AN ACCOUNT
  Future<Map<String, dynamic>> rejectAccount(
    String accountId,
    String role,
  ) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      final response = await http.put(
        Uri.parse('${baseUrl}admin/reject-account/$accountId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'role': role}),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'],
          'message': decodedResponse['message'] ?? 'Unknown error occurred',
        };
      } else {
        return {'success': false, 'message': 'Failed to reject account'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // FUNCTION TO ADD A NEW PRODUCT
  Future<Map<String, dynamic>> addProduct({
    required String title,
    required String description,
    required double amount,
    required String category,
    required String imgUrl,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      final response = await http.post(
        Uri.parse('${baseUrl}products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'amount': amount,
          'category': category,
          'imgUrl': imgUrl,
        }),
      );

      debugPrint('Add Product Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message': decodedResponse['message'],
          'product': decodedResponse['product'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add product. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Add this method just before the last closing brace of ApiService class
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      // Check if file is JPEG/JPG
      final String mimeType = imageFile.path.toLowerCase();
      if (!mimeType.endsWith('.jpg') && !mimeType.endsWith('.jpeg')) {
        return {
          'success': false,
          'message': 'Only JPEG/JPG images are allowed',
        };
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}upload/image'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $_authToken',
        'Accept': 'application/json',
      });

      // Add file to request with correct field name
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Make sure this matches the API's expected field name
          imageFile.path,
          contentType: MediaType(
            'image',
            'jpeg',
          ), // Explicitly set content type
        ),
      );

      debugPrint('Uploading image to: ${baseUrl}upload/image');
      debugPrint('Auth token: $_authToken');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message': decodedResponse['message'],
          'imageUrl': decodedResponse['imageUrl'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to upload image. Status: ${response.statusCode}, Response: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return {
        'success': false,
        'message': 'Network error occurred while uploading image: $e',
      };
    }
  }

  // FUNCTION TO GET ALL PRODUCTS
  Future<Map<String, dynamic>> getAllProducts() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'products': [],
          'count': 0,
        };
      }

      debugPrint('Fetching products from: ${baseUrl}products');

      final response = await http.get(
        Uri.parse('${baseUrl}products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Products response status: ${response.statusCode}');
      debugPrint('Products response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'] ?? false,
          'products': decodedResponse['products'] ?? [],
          'count': decodedResponse['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch products. Status: ${response.statusCode}',
          'products': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching products',
        'products': [],
        'count': 0,
      };
    }
  }

  // FUNCTION TO Create AN ORDER
  Future<Map<String, dynamic>> createOrder({
    required List<String> productIds,
    required int quantity,
    required String totalAmount,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Creating order at: ${baseUrl}orders');
      debugPrint(
        'Order details - Products: $productIds, Quantity: $quantity, Total: $totalAmount',
      );

      final response = await http.post(
        Uri.parse('${baseUrl}orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'products': productIds,
          'quantity': quantity,
          'totalAmount': totalAmount,
        }),
      );

      debugPrint('Order creation response status: ${response.statusCode}');
      debugPrint('Order creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message': decodedResponse['message'],
          'order': decodedResponse['order'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create order. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      return {
        'success': false,
        'message': 'Network error occurred while creating order',
      };
    }
  }

  // FUNCTION TO DELETE A PRODUCT
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Deleting product with ID: $productId');
      debugPrint('DELETE request to: ${baseUrl}product/$productId/delete');

      final response = await http.delete(
        Uri.parse('${baseUrl}product/$productId/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Delete product response status: ${response.statusCode}');
      debugPrint('Delete product response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'] ?? false,
          'message':
              decodedResponse['message'] ?? 'Product deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete product. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return {
        'success': false,
        'message': 'Network error occurred while deleting product',
      };
    }
  }

  // FUNCTION TO EDIT A PRODUCT
  Future<Map<String, dynamic>> editProduct({
    required String productId,
    required String title,
    required String description,
    required double amount,
    required String imgUrl,
    required String category,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Editing product with ID: $productId');
      debugPrint('PUT request to: ${baseUrl}product/$productId/edit');

      final response = await http.put(
        Uri.parse('${baseUrl}product/$productId/edit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'amount': amount,
          'imgUrl': imgUrl,
          'category': category,
        }),
      );

      debugPrint('Edit product response status: ${response.statusCode}');
      debugPrint('Edit product response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'] ?? false,
          'message':
              decodedResponse['message'] ?? 'Product updated successfully',
          'product': decodedResponse['product'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update product. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      return {
        'success': false,
        'message': 'Network error occurred while updating product',
      };
    }
  }

  // FUNCTION TO GET ALL ORDERS OF A USER
  Future<Map<String, dynamic>> getUserOrders() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'orders': [],
          'count': 0,
        };
      }

      debugPrint('Fetching orders from: ${baseUrl}orders');

      final response = await http.get(
        Uri.parse('${baseUrl}orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Orders response status: ${response.statusCode}');
      debugPrint('Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final orders = decodedResponse['orders'] as List<dynamic>;

        // Convert timestamps to DateTime for each order
        final processedOrders =
            orders.map((order) {
              if (order['createdAt'] != null) {
                final seconds = order['createdAt']['_seconds'] as int;
                final nanoseconds = order['createdAt']['_nanoseconds'] as int;

                // Convert to DateTime
                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                  seconds * 1000 + (nanoseconds / 1000000).round(),
                );

                // Format the date and time
                order['formattedCreatedAt'] = {
                  'date': '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                  'time':
                      '${dateTime.hour}:${dateTime.minute}:${dateTime.second}',
                  'timestamp': dateTime.toIso8601String(),
                };
              }

              // Also convert paymentUpdatedAt if present
              if (order['paymentUpdatedAt'] != null) {
                final seconds = order['paymentUpdatedAt']['_seconds'] as int;
                final nanoseconds =
                    order['paymentUpdatedAt']['_nanoseconds'] as int;

                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                  seconds * 1000 + (nanoseconds / 1000000).round(),
                );

                order['formattedPaymentUpdatedAt'] = {
                  'date': '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                  'time':
                      '${dateTime.hour}:${dateTime.minute}:${dateTime.second}',
                  'timestamp': dateTime.toIso8601String(),
                };
              }

              return order;
            }).toList();

        return {
          'success': decodedResponse['success'] ?? false,
          'orders': processedOrders,
          'count': decodedResponse['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders. Status: ${response.statusCode}',
          'orders': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching orders',
        'orders': [],
        'count': 0,
      };
    }
  }

  // FUNCTION TO UPDATE PAYMENT STATUS
  Future<Map<String, dynamic>> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      // Validate payment status
      final validStatuses = ['pending', 'completed', 'failed'];
      if (!validStatuses.contains(paymentStatus)) {
        return {
          'success': false,
          'message':
              'Invalid payment status. Allowed values: pending, completed, failed',
        };
      }

      debugPrint('Updating payment status for order: $orderId');
      debugPrint('New status: $paymentStatus');

      final response = await http.put(
        Uri.parse('${baseUrl}orders/$orderId/payment-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'payStatus': paymentStatus}),
      );

      debugPrint('Update payment status response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message':
              decodedResponse['message'] ??
              'Payment status updated successfully',
          'data': decodedResponse['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to update payment status. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return {
        'success': false,
        'message': 'Network error occurred while updating payment status',
      };
    }
  }

  // FUNCTION TO GET CURRENT USER PROFILE
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Fetching user profile from: ${baseUrl}auth/profile');

      final response = await http.get(
        Uri.parse('${baseUrl}auth/profile'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      debugPrint('Profile response status: ${response.statusCode}');
      debugPrint('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true &&
            decodedResponse['user'] != null) {
          final userData = decodedResponse['user'];
          return {'success': true, 'user': userData};
        }
      }

      return {'success': false, 'message': 'Failed to fetch user profile'};
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching profile',
      };
    }
  }

  // FUNCTION TO CREATE A ZONE
  Future<Map<String, dynamic>> createZone({
    required String zonalAddress,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Creating zone at: ${baseUrl}zones');
      debugPrint('Zone address: $zonalAddress');

      final response = await http.post(
        Uri.parse('${baseUrl}zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'zonalAddress': zonalAddress}),
      );

      debugPrint('Zone creation response status: ${response.statusCode}');
      debugPrint('Zone creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message': decodedResponse['message'] ?? 'Zone created successfully',
          'zone': decodedResponse['zone'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create zone. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error creating zone: $e');
      return {
        'success': false,
        'message': 'Network error occurred while creating zone',
      };
    }
  }

  // FUNCTION TO GET ALL ZONES
  Future<Map<String, dynamic>> getAllZones() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'zones': [],
          'count': 0,
        };
      }

      debugPrint('Fetching zones from: ${baseUrl}zones');

      final response = await http.get(
        Uri.parse('${baseUrl}zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Zones response status: ${response.statusCode}');
      debugPrint('Zones response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Process the zones to format timestamps and user details
        final zones =
            (decodedResponse['zones'] as List<dynamic>).map((zone) {
              // Process timestamps
              if (zone['createdAt'] != null) {
                final seconds = zone['createdAt']['_seconds'] as int;
                final nanoseconds = zone['createdAt']['_nanoseconds'] as int;
                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                  seconds * 1000 + (nanoseconds / 1000000).round(),
                );
                zone['formattedCreatedAt'] = {
                  'date': '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                  'time':
                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}',
                  'timestamp': dateTime.toIso8601String(),
                };
              }

              if (zone['updatedAt'] != null) {
                final seconds = zone['updatedAt']['_seconds'] as int;
                final nanoseconds = zone['updatedAt']['_nanoseconds'] as int;
                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                  seconds * 1000 + (nanoseconds / 1000000).round(),
                );
                zone['formattedUpdatedAt'] = {
                  'date': '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                  'time':
                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}',
                  'timestamp': dateTime.toIso8601String(),
                };
              }

              // Process user lists with both ID and name
              zone['processedDeliveryPartners'] =
                  (zone['assignedDeliveryPartners'] as List<dynamic>?)
                      ?.map(
                        (partner) => {
                          'id': partner['id'],
                          'name': partner['name'],
                          'displayText':
                              '${partner['name']} (${partner['id']})',
                        },
                      )
                      .toList() ??
                  [];

              zone['processedCustomers'] =
                  (zone['customers'] as List<dynamic>?)
                      ?.map(
                        (customer) => {
                          'id': customer['id'],
                          'name': customer['name'],
                          'displayText':
                              '${customer['name']} (${customer['id']})',
                        },
                      )
                      .toList() ??
                  [];

              zone['processedDistributors'] =
                  (zone['assignedDistributors'] as List<dynamic>?)
                      ?.map(
                        (distributor) => {
                          'id': distributor['id'],
                          'name': distributor['name'],
                          'displayText':
                              '${distributor['name']} (${distributor['id']})',
                        },
                      )
                      .toList() ??
                  [];

              return zone;
            }).toList();

        return {
          'success': true,
          'zones': zones,
          'count': decodedResponse['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch zones. Status: ${response.statusCode}',
          'zones': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching zones: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching zones',
        'zones': [],
        'count': 0,
      };
    }
  }

  // FUNCTION TO UPDATE A ZONE
  Future<Map<String, dynamic>> updateZone({
    required String zoneId,
    required String zonalAddress,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Updating zone at: ${baseUrl}zones/$zoneId');
      debugPrint('New zone address: $zonalAddress');

      final response = await http.put(
        Uri.parse('${baseUrl}zones/$zoneId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'zonalAddress': zonalAddress}),
      );

      debugPrint('Zone update response status: ${response.statusCode}');
      debugPrint('Zone update response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message': decodedResponse['message'] ?? 'Zone updated successfully',
          'zone': decodedResponse['zone'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update zone. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error updating zone: $e');
      return {
        'success': false,
        'message': 'Network error occurred while updating zone',
      };
    }
  }

  // FUNCTION TO START A SUBSCRIPTION
  Future<Map<String, dynamic>> createConnection({
    required String connectionTypeId,
    required bool waterTapNeeded,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Creating connection at: ${baseUrl}connections');
      debugPrint('Connection type ID: $connectionTypeId');
      debugPrint('Water tap needed: $waterTapNeeded');

      final response = await http.post(
        Uri.parse('${baseUrl}connections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'connectionTypeId': connectionTypeId,
          'waterTapNeeded': waterTapNeeded,
        }),
      );

      debugPrint('Connection creation response status: ${response.statusCode}');
      debugPrint('Connection creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message':
              decodedResponse['message'] ?? 'Connection created successfully',
          'connection': decodedResponse['connection'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to create connection. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error creating connection: $e');
      return {
        'success': false,
        'message': 'Network error occurred while creating connection',
      };
    }
  }

  // FUNCTION TO GET ALL ORDERS
  Future<Map<String, dynamic>> getAllOrders() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'orders': [],
          'count': 0,
        };
      }

      debugPrint('Fetching orders from: ${baseUrl}orders');

      final response = await http.get(
        Uri.parse('${baseUrl}orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Orders response status: ${response.statusCode}');
      debugPrint('Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final List<dynamic> rawOrders = decodedResponse['orders'] ?? [];
        final List<Map<String, dynamic>> processedOrders = [];

        for (var order in rawOrders) {
          final Map<String, dynamic> processedOrder = {...order};

          // Add zone information
          processedOrder['zone'] = order['zone'] ?? 'N/A';

          // Process createdAt timestamp
          if (order['createdAt'] != null) {
            final seconds = order['createdAt']['_seconds'] as int;
            final nanoseconds = order['createdAt']['_nanoseconds'] as int;
            final createdAtDateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            processedOrder['formattedCreatedAt'] = {
              'date':
                  '${createdAtDateTime.day}/${createdAtDateTime.month}/${createdAtDateTime.year}',
              'time':
                  '${createdAtDateTime.hour.toString().padLeft(2, '0')}:${createdAtDateTime.minute.toString().padLeft(2, '0')}:${createdAtDateTime.second.toString().padLeft(2, '0')}',
              'timestamp': createdAtDateTime.toIso8601String(),
            };
          }

          // Process paymentUpdatedAt timestamp if exists
          if (order['paymentUpdatedAt'] != null) {
            final seconds = order['paymentUpdatedAt']['_seconds'] as int;
            final nanoseconds =
                order['paymentUpdatedAt']['_nanoseconds'] as int;
            final paymentDateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            processedOrder['formattedPaymentUpdatedAt'] = {
              'date':
                  '${paymentDateTime.day}/${paymentDateTime.month}/${paymentDateTime.year}',
              'time':
                  '${paymentDateTime.hour.toString().padLeft(2, '0')}:${paymentDateTime.minute.toString().padLeft(2, '0')}:${paymentDateTime.second.toString().padLeft(2, '0')}',
              'timestamp': paymentDateTime.toIso8601String(),
            };
          }

          // Add calculated total price
          processedOrder['formattedAmount'] =
              '₹${double.parse(order['totalAmount'].toString()).toStringAsFixed(2)}';

          // Add status indicators
          processedOrder['isCompleted'] =
              order['payStatus'] == 'completed' &&
              order['deliveryStatus'] == 'completed';
          processedOrder['isPending'] =
              order['payStatus'] == 'pending' ||
              order['deliveryStatus'] == 'pending';
          processedOrder['isFailed'] = order['payStatus'] == 'failed';
          processedOrder['isOnTheWay'] =
              order['deliveryStatus'] == 'on_the_way';

          // Add order identifier
          processedOrder['orderId'] = order['orderId'] ?? 'N/A';
          processedOrder['buyerRole'] = order['buyerRole'] ?? 'N/A';
          processedOrder['buyer'] = order['buyer'] ?? 'N/A';

          processedOrders.add(processedOrder);
        }

        return {
          'success': true,
          'orders': processedOrders,
          'count': decodedResponse['count'] ?? 0,
          'message': 'Orders fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders. Status: ${response.statusCode}',
          'orders': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching orders',
        'orders': [],
        'count': 0,
      };
    }
  }

  // FUNCTION TO ASSIGN ZONE TO A USER
  Future<Map<String, dynamic>> assignUsersToZone({
    required String zoneId,
    List<String> distributors = const [],
    List<String> deliveryPartners = const [],
    List<String> customers = const [],
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      // Validate that only one type of user is being assigned
      int nonEmptyLists = 0;
      if (distributors.isNotEmpty) nonEmptyLists++;
      if (deliveryPartners.isNotEmpty) nonEmptyLists++;
      if (customers.isNotEmpty) nonEmptyLists++;

      if (nonEmptyLists != 1) {
        return {
          'success': false,
          'message': 'Please assign only one type of user at a time',
        };
      }

      debugPrint('Assigning users to zone: $zoneId');
      debugPrint('Distributors: $distributors');
      debugPrint('Delivery Partners: $deliveryPartners');
      debugPrint('Customers: $customers');

      // Updated endpoint URL to match the backend
      final response = await http.post(
        Uri.parse('${baseUrl}admin/zones/$zoneId/assign-users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'distributors': distributors,
          'deliveryPartners': deliveryPartners,
          'customers': customers,
        }),
      );

      debugPrint('Zone assignment response status: ${response.statusCode}');
      debugPrint('Zone assignment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message':
              decodedResponse['message'] ?? 'Users assigned successfully',
          'data': decodedResponse['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to assign users. Status: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      debugPrint('Error assigning users to zone: $e');
      return {
        'success': false,
        'message': 'Network error occurred while assigning users to zone',
        'error': e.toString(),
      };
    }
  }

  // FUNCTION TO GET ALL ORDERS FOR DELIVERY PARTNER
  Future<Map<String, dynamic>> getDeliveryOrdersByZone(String zoneId) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'orders': [],
          'count': 0,
        };
      }

      debugPrint('Fetching delivery orders for zone: $zoneId');

      final response = await http.get(
        Uri.parse('${baseUrl}delivery/orders/zone/$zoneId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Delivery orders response status: ${response.statusCode}');
      debugPrint('Delivery orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final List<dynamic> rawOrders = decodedResponse['orders'] ?? [];
        final List<Map<String, dynamic>> processedOrders = [];

        for (var order in rawOrders) {
          final Map<String, dynamic> processedOrder = {...order};

          // Process createdAt timestamp
          if (order['createdAt'] != null) {
            final seconds = order['createdAt']['_seconds'] as int;
            final nanoseconds = order['createdAt']['_nanoseconds'] as int;
            final createdAtDateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            processedOrder['formattedCreatedAt'] = {
              'date':
                  '${createdAtDateTime.day}/${createdAtDateTime.month}/${createdAtDateTime.year}',
              'time':
                  '${createdAtDateTime.hour.toString().padLeft(2, '0')}:${createdAtDateTime.minute.toString().padLeft(2, '0')}:${createdAtDateTime.second.toString().padLeft(2, '0')}',
              'timestamp': createdAtDateTime.toIso8601String(),
            };
          }

          // Add formatted amount
          processedOrder['formattedAmount'] =
              '₹${double.parse(order['totalAmount'].toString()).toStringAsFixed(2)}';

          // Add delivery status indicators
          processedOrder['isCompleted'] =
              order['deliveryStatus'] == 'completed';
          processedOrder['isPending'] = order['deliveryStatus'] == 'pending';
          processedOrder['isOnTheWay'] =
              order['deliveryStatus'] == 'on_the_way';
          processedOrder['paymentStatus'] = order['payStatus'] ?? 'unknown';

          // Ensure order identifiers are present
          processedOrder['orderId'] = order['orderId'] ?? 'N/A';
          processedOrder['buyerRole'] = order['buyerRole'] ?? 'N/A';
          processedOrder['buyer'] = order['buyer'] ?? 'N/A';
          processedOrder['zone'] = order['zone'] ?? 'N/A';
          processedOrder['products'] = order['products'] ?? [];
          processedOrder['quantity'] = order['quantity'] ?? 0;

          processedOrders.add(processedOrder);
        }

        return {
          'success': true,
          'orders': processedOrders,
          'count': decodedResponse['count'] ?? 0,
          'message': 'Delivery orders fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch delivery orders. Status: ${response.statusCode}',
          'orders': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching delivery orders: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching delivery orders',
        'orders': [],
        'count': 0,
      };
    }
  }

  // FUNCTION TO UPDATE PAYMENT AND DELIVERY STATUS FOR DELIVERY PARTNER
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String deliveryStatus,
    required String payStatus,
  }) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      // Validate delivery status
      final validDeliveryStatuses = ['pending', 'delivered', 'failed'];
      if (!validDeliveryStatuses.contains(deliveryStatus)) {
        return {
          'success': false,
          'message':
              'Invalid delivery status. Allowed values: pending, delivered, failed',
        };
      }

      // Validate payment status
      final validPaymentStatuses = ['pending', 'completed', 'failed'];
      if (!validPaymentStatuses.contains(payStatus)) {
        return {
          'success': false,
          'message':
              'Invalid payment status. Allowed values: pending, completed, failed',
        };
      }

      debugPrint('Updating order status for order ID: $orderId');
      debugPrint('New delivery status: $deliveryStatus');
      debugPrint('New payment status: $payStatus');

      final response = await http.put(
        Uri.parse('${baseUrl}orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'deliveryStatus': deliveryStatus,
          'payStatus': payStatus,
        }),
      );

      debugPrint('Update status response code: ${response.statusCode}');
      debugPrint('Update status response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message':
              decodedResponse['message'] ?? 'Order status updated successfully',
          'orderId': decodedResponse['orderId'],
          'deliveryStatus': decodedResponse['deliveryStatus'],
          'payStatus': decodedResponse['payStatus'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to update order status. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return {
        'success': false,
        'message': 'Network error occurred while updating order status',
      };
    }
  }

  // FUNCTION TO GET ALL COMPLETED DELIVERY ORDERS
  Future<Map<String, dynamic>> getAllCompletedDeliveries() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'deliveries': [],
          'count': 0,
        };
      }

      final response = await http.get(
        Uri.parse('${baseUrl}delivery/all-deliveries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint(
        'Completed deliveries response status: ${response.statusCode}',
      );
      debugPrint('Completed deliveries response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final List<dynamic> rawDeliveries = decodedResponse['deliveries'] ?? [];
        final List<Map<String, dynamic>> processedDeliveries = [];

        for (var delivery in rawDeliveries) {
          final Map<String, dynamic> processedDelivery = {...delivery};

          // Keep all connections that are active
          if (delivery['type'] == 'connection' &&
              delivery['status'] == 'active') {
            processedDeliveries.add(processedDelivery);
          }
          // Keep all orders regardless of status for now (we can filter if needed)
          else if (delivery['type'] == 'order') {
            processedDeliveries.add(processedDelivery);
          }

          // Format amount for display
          if (processedDelivery['totalAmount'] != null) {
            processedDelivery['formattedAmount'] =
                '₹${double.parse(processedDelivery['totalAmount'].toString()).toStringAsFixed(2)}';
          } else if (processedDelivery['amount'] != null) {
            processedDelivery['formattedAmount'] =
                '₹${processedDelivery['amount'].toString()}';
          }
        }

        return {
          'success': true,
          'deliveries': processedDeliveries,
          'count': processedDeliveries.length,
          'message': 'Deliveries fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch deliveries. Status: ${response.statusCode}',
          'deliveries': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching deliveries',
        'deliveries': [],
        'count': 0,
      };
    }
  }

  // FUNCTION TO CHECK IF THE USER's SUBSCRIPTION DETAILS
  Future<Map<String, dynamic>> getUserConnectionDetails(String userId) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint(
        'Fetching connection details from: ${baseUrl}connections/$userId',
      );

      final response = await http.get(
        Uri.parse('${baseUrl}connections/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Connection details response status: ${response.statusCode}');
      debugPrint('Connection details response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (!decodedResponse['success']) {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'No connection found',
            'hasConnection': false,
          };
        }

        if (decodedResponse['connections']?.isNotEmpty ?? false) {
          final connection = decodedResponse['connections'][0];

          // Format the timestamp
          final DateTime createdAt =
              connection['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                    connection['createdAt']['_seconds'] * 1000 +
                        (connection['createdAt']['_nanoseconds'] / 1000000)
                            .round(),
                  )
                  : DateTime.now();

          return {
            'success': true,
            'hasConnection': true,
            'connectionDetails': {
              'id': connection['id'],
              'connectionId': connection['connectionId'],
              'connectionTypeId': connection['connectionTypeId'],
              'connectionType': connection['connectionType'],
              'waterTapNeeded': connection['waterTapNeeded'],
              'status': connection['status'],
              'amount': connection['amount'],
              'dueAmount': connection['dueAmount'],
              'zoneId': connection['zoneId'],
              'address': connection['address'],
              'createdAt': {
                'date': '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                'time':
                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                'timestamp': createdAt.toIso8601String(),
              },
            },
          };
        }

        return {
          'success': false,
          'message': 'No connection details found',
          'hasConnection': false,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch connection details. Status: ${response.statusCode}',
          'hasConnection': false,
        };
      }
    } catch (e) {
      debugPrint('Error fetching connection details: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching connection details',
        'hasConnection': false,
      };
    }
  }

  // FUNCTION TO GET ALL COMPLETED DELIVERED ORDERS
  Future<Map<String, dynamic>> getCompletedOrdersByZone(String zoneId) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'orders': [],
          'count': 0,
        };
      }

      debugPrint('Fetching completed orders for zone: $zoneId');

      final response = await http.get(
        Uri.parse('${baseUrl}delivery/orders/zone/$zoneId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Completed orders response status: ${response.statusCode}');
      debugPrint('Completed orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final List<dynamic> rawOrders = decodedResponse['orders'] ?? [];
        final List<Map<String, dynamic>> processedOrders = [];

        for (var order in rawOrders) {
          final Map<String, dynamic> processedOrder = {...order};

          // Process timestamps
          if (order['createdAt'] != null) {
            final seconds = order['createdAt']['_seconds'] as int;
            final nanoseconds = order['createdAt']['_nanoseconds'] as int;
            final createdAtDateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            processedOrder['formattedCreatedAt'] = {
              'date':
                  '${createdAtDateTime.day}/${createdAtDateTime.month}/${createdAtDateTime.year}',
              'time':
                  '${createdAtDateTime.hour.toString().padLeft(2, '0')}:${createdAtDateTime.minute.toString().padLeft(2, '0')}:${createdAtDateTime.second.toString().padLeft(2, '0')}',
              'timestamp': createdAtDateTime.toIso8601String(),
            };
          }

          // Process payment timestamp if exists
          if (order['paymentUpdatedAt'] != null) {
            final seconds = order['paymentUpdatedAt']['_seconds'] as int;
            final nanoseconds =
                order['paymentUpdatedAt']['_nanoseconds'] as int;
            final paymentDateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            processedOrder['formattedPaymentUpdatedAt'] = {
              'date':
                  '${paymentDateTime.day}/${paymentDateTime.month}/${paymentDateTime.year}',
              'time':
                  '${paymentDateTime.hour.toString().padLeft(2, '0')}:${paymentDateTime.minute.toString().padLeft(2, '0')}:${paymentDateTime.second.toString().padLeft(2, '0')}',
              'timestamp': paymentDateTime.toIso8601String(),
            };
          }

          // Add formatted amount
          processedOrder['formattedAmount'] =
              '₹${double.parse(order['totalAmount'].toString()).toStringAsFixed(2)}';

          // Add buyer information
          processedOrder['buyerInfo'] = {
            'id': order['buyer'],
            'name': order['buyerName'] ?? 'N/A',
            'role': order['buyerRole'] ?? 'N/A',
          };

          processedOrders.add(processedOrder);
        }

        return {
          'success': true,
          'orders': processedOrders,
          'count': decodedResponse['count'] ?? 0,
          'message': 'Completed orders fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch completed orders. Status: ${response.statusCode}',
          'orders': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching completed orders: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching completed orders',
        'orders': [],
        'count': 0,
      };
    }
  }

  //FUNCTION TO GET USER INFO USING USER ID
  Future<Map<String, dynamic>> getUserInfo(String userId, String role) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'user': null,
        };
      }

      // Determine the endpoint based on role
      final String endpoint = role.toLowerCase() == 'distributor' 
          ? 'distributor'
          : 'customer';

      debugPrint('Fetching $role info for ID: $userId');

      final response = await http.get(
        Uri.parse('${baseUrl}admin-delivery/account/$userId/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('User info response status: ${response.statusCode}');
      debugPrint('User info response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse['success'] && decodedResponse['user'] != null) {
          final userData = decodedResponse['user'];

          // Process timestamps if they exist
          if (userData['createdAt'] != null) {
            final seconds = userData['createdAt']['_seconds'] as int;
            final nanoseconds = userData['createdAt']['_nanoseconds'] as int;
            final createdAtDateTime = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds / 1000000).round(),
            );
            userData['formattedCreatedAt'] = {
              'date': '${createdAtDateTime.day}/${createdAtDateTime.month}/${createdAtDateTime.year}',
              'time': '${createdAtDateTime.hour.toString().padLeft(2, '0')}:${createdAtDateTime.minute.toString().padLeft(2, '0')}',
              'timestamp': createdAtDateTime.toIso8601String(),
            };
          }

          return {
            'success': true,
            'user': userData,
            'message': 'User information fetched successfully',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to fetch user information. Status: ${response.statusCode}',
        'user': null,
      };
    } catch (e) {
      debugPrint('Error fetching user information: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching user information',
        'user': null,
      };
    }
  }

  // FUNCTION TO REQUEST FOR NEW JAR FOR CONNECTION
  Future<Map<String, dynamic>> requestNewJar(String connectionId) async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
        };
      }

      debugPrint('Requesting new jar for connection: $connectionId');

      final response = await http.post(
        Uri.parse('${baseUrl}deliver-connections/request/$connectionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Request jar response status: ${response.statusCode}');
      debugPrint('Request jar response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'message':
              decodedResponse['message'] ?? 'Water jar requested successfully',
          'deliveryConnection': decodedResponse['deliverConnection'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to request water jar. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error requesting water jar: $e');
      return {
        'success': false,
        'message': 'Network error occurred while requesting water jar',
      };
    }
  }

  // FUNCTION TO GET ALL EXISTING CONNECTION TYPES
  Future<Map<String, dynamic>> getAllConnectionTypes() async {
    try {
      if (_authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'connections': [],
          'count': 0,
        };
      }

      debugPrint('Fetching connection types from: ${baseUrl}connection-types');

      final response = await http.get(
        Uri.parse('${baseUrl}connection-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('Connection types response status: ${response.statusCode}');
      debugPrint('Connection types response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': true,
          'connections': decodedResponse['connections'] ?? [],
          'count': decodedResponse['count'] ?? 0,
          'message': 'Connection types fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch connection types. Status: ${response.statusCode}',
          'connections': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching connection types: $e');
      return {
        'success': false,
        'message': 'Network error occurred while fetching connection types',
        'connections': [],
        'count': 0,
      };
    }
  }
}
