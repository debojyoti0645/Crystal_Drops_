import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price, 'quantity': quantity};
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  static const String _cartKey = 'cart_items';

  CartProvider() {
    _loadCartFromPrefs();
  }

  // Add this to your CartProvider class
void clear() {
    _items = {};
  notifyListeners();
}

  Map<String, CartItem> get items => {..._items};

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = _items.map((key, item) => MapEntry(key, item.toMap()));
    await prefs.setString(_cartKey, jsonEncode(cartData));
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey);

    if (cartString != null) {
      final Map<String, dynamic> cartMap = jsonDecode(cartString);
      _items = cartMap.map(
        (key, value) =>
            MapEntry(key, CartItem.fromMap(Map<String, dynamic>.from(value))),
      );
      notifyListeners();
    }
  }

  Future<void> addItem(String productId, String name, double price) async {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: productId,
          name: name,
          price: price,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items[productId] = CartItem(
        id: productId,
        name: name,
        price: price,
        quantity: 1,
      );
    }
    await _saveCartToPrefs();
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    await _saveCartToPrefs();
    notifyListeners();
  }

  Future<void> removeQuantity(String productId, int quantity) async {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity <= quantity) {
      await removeItem(productId);
    } else {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          quantity: existingItem.quantity - quantity,
          price: existingItem.price,
        ),
      );
      await _saveCartToPrefs();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    notifyListeners();
  }
}
