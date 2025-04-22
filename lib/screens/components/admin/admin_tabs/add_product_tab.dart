import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:water_supply/service/api_service.dart';

class AddProductTab extends StatefulWidget {
  const AddProductTab({super.key});

  @override
  State<AddProductTab> createState() => _AddProductTabState();
}

class _AddProductTabState extends State<AddProductTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final ApiService _apiService = ApiService();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? selectedCategory;

  final String category = 'water_bottles';

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    selectedCategory = category;
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.initializeAuthToken();
      if (_apiService.authToken == null) {
        throw Exception('Authentication token not available');
      }
      final response = await _apiService.uploadImage(_selectedImage!);
      if (response['success']) {
        setState(() {
          _imageUrlController.text = response['imageUrl'];
        });
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Add StatefulBuilder to update dialog UI
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final XFile? pickedFile = await _picker.pickImage(
                                source: ImageSource.camera,
                              );
                              if (pickedFile != null) {
                                setDialogState(() {
                                  // Update dialog state
                                  _selectedImage = File(pickedFile.path);
                                });
                                setState(() {}); // Update parent state
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final XFile? pickedFile = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                setDialogState(() {
                                  // Update dialog state
                                  _selectedImage = File(pickedFile.path);
                                });
                                setState(() {}); // Update parent state
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImage != null)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _uploadSelectedImage,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Upload Image'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _initializeApiService() async {
    await _apiService.initializeAuthToken();
  }

  Future<void> _handleAddProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double? amount = double.tryParse(_priceController.text);
      if (amount == null) {
        throw Exception('Invalid price format');
      }

      final response = await _apiService.addProduct(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        category: selectedCategory ?? '',
        imgUrl: _imageUrlController.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Navigate to home screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/s_admin_home', // Replace with your home route name
          (route) => false, // This will remove all previous routes
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to add product'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    if (!mounted) return;

    setState(() {
      _titleController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _selectedImage = null;
      selectedCategory = category;
    });

    _formKey.currentState?.reset(); // Reset form validation states
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Product',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Product Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(
                          Icons.shopping_bag,
                          color: Colors.blue,
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter product title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          color: Colors.blue,
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.description, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Image',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    enabled: false,
                                    obscureText: true,
                                    readOnly: true,
                                    controller: _imageUrlController,
                                    decoration: InputDecoration(
                                      labelText: 'Image URL',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please upload an image';
                                      }
                                      if (!Uri.tryParse(value!)!.isAbsolute) {
                                        return 'Invalid image URL';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _showImagePickerDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.upload,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Upload',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleAddProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Add Product',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
