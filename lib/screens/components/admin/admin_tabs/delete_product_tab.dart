import 'package:flutter/material.dart';
import 'package:water_supply/service/api_service.dart';

class DeleteProductTab extends StatefulWidget {
  const DeleteProductTab({super.key});

  @override
  State<DeleteProductTab> createState() => _DeleteProductTabState();
}

class _DeleteProductTabState extends State<DeleteProductTab> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.initializeAuthToken();
      final response = await _apiService.getAllProducts();
      debugPrint('Products response: $response'); // Add debug logging

      if (response['success']) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response['products']);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to load products'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading products: $e'); // Add debug logging
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteProduct(String? productId) async {
    if (productId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid product ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final response = await _apiService.deleteProduct(productId);
      debugPrint('Delete response: $response'); // Add debug logging

      if (response['success']) {
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting product: $e'); // Add debug logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No products available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['imgUrl'] ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error),
                      ),
                ),
              ),
              title: Text(
                product['title'] ?? 'Untitled',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '₹${product['amount']?.toString() ?? '0'}\n${product['description'] ?? 'No description'}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Product'),
                          content: const Text(
                            'Are you sure you want to delete this product?',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                final productId =
                                    product['_id'] ??
                                    product['id']; // Try both field names
                                debugPrint(
                                  'Deleting product with ID: $productId',
                                ); // Add debug logging
                                _handleDeleteProduct(productId);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
