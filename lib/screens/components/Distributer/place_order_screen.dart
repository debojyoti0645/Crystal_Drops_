import 'package:flutter/material.dart';
import 'package:water_supply/screens/components/Distributer/dist_payment%20page.dart';
import 'package:water_supply/service/api_service.dart';

class PlaceOrderScreen extends StatefulWidget {
  final bool shouldReset;

  const PlaceOrderScreen({super.key, this.shouldReset = false});

  @override
  _PlaceOrderScreenState createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  Map<String, int> _orderQuantities = {};
  final TextEditingController _searchController = TextEditingController();
  static const int MIN_ORDER_QUANTITY = 12;
  static const int MAX_ORDER_QUANTITY = 24;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
    if (widget.shouldReset) {
      _resetState();
    }
  }

  void _resetState() {
    setState(() {
      _orderQuantities.clear();
      _searchController.clear();
      _filterProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _filterProducts() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts =
            _products.where((product) {
              final String title =
                  (product['title'] ?? '').toString().toLowerCase();
              return title.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.initializeAuthToken();
      final response = await _apiService.getAllProducts();

      if (response['success']) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response['products']);
          _filteredProducts = _products;
          for (var product in _products) {
            _orderQuantities[product['id']] = 0;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load products'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var product in _products) {
      total +=
          (product['amount'] ?? 0) * (_orderQuantities[product['id']] ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Place Bulk Order',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: Color(0xFF007BFF)),
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF007BFF),
                            ),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Color(0xFF007BFF),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterProducts();
                                      },
                                    )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                          ),
                          onChanged: (value) => _filterProducts(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return Card(
                            elevation: 8,
                            shadowColor: Colors.blue.withOpacity(0.2),
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Color(0xFFE3F2FD)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'product-${product['id']}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          product['imgUrl'] ?? '',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFE3F2FD),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.error_outline,
                                                      color: Color(0xFF007BFF),
                                                      size: 32,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['title'] ?? 'Untitled',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A237E),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            product['description'] ??
                                                'No description',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '₹${product['amount']?.toString() ?? '0'}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00C853),
                                                ),
                                              ),
                                              _buildQuantityControls(product),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
      ),
    );
  }

  Widget _buildQuantityControls(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildQuantityButton(Icons.remove, () {
                setState(() {
                  final currentQty = _orderQuantities[product['id']] ?? 0;
                  if (currentQty >= MIN_ORDER_QUANTITY + 12) {
                    _orderQuantities[product['id']] = currentQty - 12;
                  } else if (currentQty > 0) {
                    _orderQuantities[product['id']] = 0;
                  }
                });
              }),
              SizedBox(
                width: 50,
                child: Text(
                  '${_orderQuantities[product['id']] ?? 0}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007BFF),
                  ),
                ),
              ),
              _buildQuantityButton(Icons.add, () {
                setState(() {
                  final currentQty = _orderQuantities[product['id']] ?? 0;
                  if (currentQty < MAX_ORDER_QUANTITY) {
                    _orderQuantities[product['id']] = currentQty + 12;
                  } else {
                    // Show max limit reached message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maximum order quantity (24) reached for this item'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(icon, size: 24, color: Color(0xFF007BFF)),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Text(
                    '₹${_calculateTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007BFF),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _navigateToPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                shadowColor: Color(0xFF007BFF).withOpacity(0.5),
              ),
              child: Text(
                'Place Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPayment() {
    final selectedItems =
        _filteredProducts
            .where((product) {
              final quantity = _orderQuantities[product['id']] ?? 0;
              return quantity >= MIN_ORDER_QUANTITY;
            })
            .map(
              (product) => {
                ...product,
                'quantity': _orderQuantities[product['id']] ?? 0,
              },
            )
            .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one product with minimum 12 units',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all selected items meet minimum quantity
    bool hasInvalidQuantity = _orderQuantities.entries.any((entry) {
      final quantity = entry.value;
      return quantity > 0 && quantity < MIN_ORDER_QUANTITY;
    });

    if (hasInvalidQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each selected product must have at least 12 units'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalQuantity = _orderQuantities.values.fold(
      0,
      (sum, qty) => sum + qty,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DistributorPaymentPage(
              selectedItems: selectedItems,
              totalAmount: _calculateTotal(),
              totalQuantity: totalQuantity,
            ),
      ),
    );
  }
}
