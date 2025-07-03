import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Maps_flutter/Maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as app_location;
import 'package:shared_preferences/shared_preferences.dart'; // เพิ่ม SharedPreferences
// import 'package:sqflite/sqflite.dart'; // ไม่จำเป็นต้อง import database ที่นี่โดยตรง
// import 'package:path/path.dart' as path; // ไม่จำเป็นต้อง import path ที่นี่โดยตรง

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/shop_model.dart';
import '../models/location_model.dart' as app_location; // Alias เพื่อหลีกเลี่ยงการชนกับ Maps_flutter.LatLng
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../database/database_helper.dart'; // DatabaseHelper อาจจะไม่ถูกเรียกใช้โดยตรงถ้าผ่าน Repository
import '../database/repository.dart'; // Import Repository

class BuyerProvider with ChangeNotifier {
  final Repository _repository; // ใช้ Repository แทน DatabaseHelper โดยตรง
  bool _isInitialized = false;

  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _popularProducts = [];
  List<Product> _newArrivals = [];
  app_location.Location? _currentLocation; // ใช้ app_location.Location
  List<Shop> _nearbyShops = [];
  final Map<int, int> _cart = {}; // Map: productId -> quantity

  BuyerProvider() : _repository = Repository() {
    // Initialize when the provider is created
    // Initialization logic moved to the `initialize` method for async operations
  }

  bool get isInitialized => _isInitialized;
  List<Category> get categories => _categories;
  List<Product> get allProducts => _allProducts;
  List<Product> get popularProducts => _popularProducts;
  List<Product> get newArrivals => _newArrivals;
  app_location.Location? get currentLocation => _currentLocation;
  List<Shop> get nearbyShops => _nearbyShops;
  Map<int, int> get cart => _cart;
  int get cartItemCount => _cart.values.fold(0, (sum, count) => sum + count);

  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing BuyerProvider...');

      // Ensure the database is ready via Repository
      await _repository.ensureDatabaseInitialized(); // เพิ่มเมธอดนี้ใน Repository

      // Load initial data
      await loadInitialData();
      await _loadUserLocation(); // โหลดตำแหน่งจาก prefs
      await _loadCartFromPrefs(); // โหลดตะกร้าสินค้าจาก prefs

      _isInitialized = true;
      debugPrint('BuyerProvider initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BuyerProvider: $e');
      // Handle initialization errors, e.g., show a message to the user
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Load initial data like categories, all products, etc.
  Future<void> loadInitialData() async {
    try {
      _categories = (await _repository.getAllCategories()).cast<Category>();
      _allProducts = (await _repository.getAllProducts()).cast<Product>();
      _popularProducts = await getPopularProducts(); // ดึงข้อมูลสินค้าแนะนำ
      _newArrivals = await getNewArrivals(); // ดึงข้อมูลสินค้ามาใหม่
      debugPrint('Initial data loaded: ${categories.length} categories, ${allProducts.length} products');
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
    notifyListeners();
  }

  // User location management
  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('current_location_lat');
    final lng = prefs.getDouble('current_location_lng');
    final address = prefs.getString('current_location_address');

    if (lat != null && lng != null) {
      _currentLocation = app_location.Location(
        latitude: lat,
        longitude: lng,
        address: address, timestamp: null,
      );
      // Optional: Load nearby shops immediately after location is loaded
      // if (_currentLocation != null) {
      //   await getNearbyShops(LatLng(_currentLocation!.latitude, _currentLocation!.longitude));
      // }
    }
    notifyListeners();
  }

  Future<void> updateUserLocation(app_location.Location newLocation) async {
    _currentLocation = newLocation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_location_lat', newLocation.latitude);
    await prefs.setDouble('current_location_lng', newLocation.longitude);
    if (newLocation.address != null) {
      await prefs.setString('current_location_address', newLocation.address!);
    } else {
      await prefs.remove('current_location_address');
    }
    await getNearbyShops(LatLng(newLocation.latitude, newLocation.longitude)); // อัปเดตร้านค้าใกล้เคียง
    notifyListeners();
  }

  // Product and Category Operations
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      return (await _repository.getProductsByCategory(categoryId)).cast<Product>();
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return [];
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      return (await _repository.searchProducts(query)).cast<Product>();
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  Future<Product?> getProductDetails(int productId) async {
    try {
      return await _repository.getProduct(productId);
    } catch (e) {
      debugPrint('Error getting product details: $e');
      return null;
    }
  }

  Future<List<Product>> getRelatedProducts(int productId) async {
    try {
      // For simplicity, just return some products.
      // A more complex implementation would involve product tags, categories, etc.
      final allProducts = await _repository.getAllProducts();
      return allProducts.where((p) => p.id != productId).take(5).toList().cast<Product>();
    } catch (e) {
      debugPrint('Error getting related products: $e');
      return [];
    }
  }

  Future<List<Product>> getPopularProducts({int limit = 20}) async {
    try {
      // Example: Products with highest order counts or views
      // This would require a 'views' or 'order_count' field in Product model or separate tracking.
      // For now, let's just return a subset of all products.
      final all = await _repository.getAllProducts();
      return all.take(limit).toList().cast<Product>(); // Dummy implementation
    } catch (e) {
      debugPrint('Error getting popular products: $e');
      return [];
    }
  }

  Future<List<Product>> getNewArrivals({int limit = 20}) async {
    try {
      // Example: Products ordered by creation date
      final newProducts = await _repository.getNewArrivalsProducts(limit: limit);
      return newProducts.cast<Product>();
    } catch (e) {
      debugPrint('Error getting new arrivals: $e');
      return [];
    }
  }

  // Shop Operations
  Future<List<Shop>> searchShops(String query) async {
    try {
      return (await _repository.searchShops(query)).cast<Shop>();
    } catch (e) {
      debugPrint('Error searching shops: $e');
      return [];
    }
  }

  Future<Shop?> getShopDetails(int shopId) async {
    try {
      return await _repository.getShop(shopId);
    } catch (e) {
      debugPrint('Error getting shop details: $e');
      return null;
    }
  }

  Future<List<Product>> getShopProducts(int shopId, {int? categoryId}) async {
    try {
      return (await _repository.getProductsByShop(shopId, categoryId: categoryId)).cast<Product>();
    } catch (e) {
      debugPrint('Error getting shop products: $e');
      return [];
    }
  }

  Future<List<Shop>> getNearbyShops(LatLng location, {double radiusInKm = 5.0}) async {
    try {
      _nearbyShops = (await _repository.getNearbyShops(
        location.latitude,
        location.longitude,
        radiusInKm: radiusInKm,
      )).cast<Shop>();
      notifyListeners();
      return _nearbyShops;
    } catch (e) {
      debugPrint('Error getting nearby shops: $e');
      return [];
    }
  }

  // Cart Management
  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart');
    if (cartJson != null) {
      final Map<String, dynamic> decodedCart = json.decode(cartJson);
      _cart.clear();
      decodedCart.forEach((key, value) {
        _cart[int.parse(key)] = value as int;
      });
      debugPrint('Cart loaded from preferences: $_cart');
    }
    notifyListeners();
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedCart = json.encode(_cart.map((key, value) => MapEntry(key.toString(), value)));
    await prefs.setString('cart', encodedCart);
    debugPrint('Cart saved to preferences: $_cart');
  }

  void addToCart(Product product, int quantity) {
    _cart.update(product.id!, (value) => value + quantity, ifAbsent: () => quantity);
    _saveCartToPrefs();
    notifyListeners();
    debugPrint('Added ${quantity} of ${product.name} to cart. Current cart: $_cart');
  }

  void removeFromCart(int productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]! > 1) {
        _cart.update(productId, (value) => value - 1);
      } else {
        _cart.remove(productId);
      }
      _saveCartToPrefs();
      notifyListeners();
      debugPrint('Removed 1 of product ID $productId from cart. Current cart: $_cart');
    }
  }

  void removeAllOfProductFromCart(int productId) {
    _cart.remove(productId);
    _saveCartToPrefs();
    notifyListeners();
    debugPrint('Removed all of product ID $productId from cart. Current cart: $_cart');
  }

  void clearCart() {
    _cart.clear();
    _saveCartToPrefs();
    notifyListeners();
    debugPrint('Cart cleared.');
  }

  // Order Operations (Placeholder for now)
  Future<bool> placeOrder(int userId, String shippingAddress, List<Map<String, dynamic>> items) async {
    // items should be [{productId: ..., quantity: ..., price: ...}, ...]
    try {
      double totalAmount = 0;
      for (var item in items) {
        totalAmount += item['quantity'] * item['price'];
      }

      final orderMap = {
        'userId': userId,
        'totalAmount': totalAmount,
        'status': 'pending', // Initial status
        'shippingAddress': shippingAddress,
        'orderDate': DateTime.now().toIso8601String(),
      };

      final orderId = await _repository.insertOrder(orderMap);

      if (orderId > 0) {
        for (var item in items) {
          final orderItemMap = {
            'orderId': orderId,
            'productId': item['productId'],
            'quantity': item['quantity'],
            'price': item['price'],
          };
          await _repository.insertOrderItem(orderItemMap);
        }
        clearCart(); // Clear cart after successful order
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return false;
    }
  }

  Future<List<dynamic>> getUserOrders(int userId) async {
    try {
      // Assuming Repository has a method to get orders with their items
      return await _repository.getUserOrders(userId);
    } catch (e) {
      debugPrint('Error getting user orders: $e');
      return [];
    }
  }
}