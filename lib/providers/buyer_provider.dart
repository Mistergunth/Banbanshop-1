import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/shop_model.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../models/location_model.dart';
import '../database/database_helper.dart';

class BuyerProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  bool _isInitialized = false;
  
  BuyerProvider() : _databaseHelper = DatabaseHelper() {
    // Initialize when the provider is created
    initialize();
  }
  
  bool get isInitialized => _isInitialized;
  
  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('Initializing BuyerProvider...');
      
      // Initialize database
      final db = await _databaseHelper.database;
      print('Database initialized successfully');
      
      // Load initial data
      await loadInitialData();
      
      _isInitialized = true;
      print('BuyerProvider initialized successfully');
    } catch (e) {
      print('Error initializing BuyerProvider: $e');
      rethrow;
    }
  }
  
  // Current selected location
  Province? _selectedProvince;
  District? _selectedDistrict;
  
  // Current selected category
  ProductCategory? _selectedCategory;
  
  // Current view mode (products or shops)
  String _viewMode = 'products';
  bool _isGridView = true;
  
  // Search query
  String _searchQuery = '';
  
  // Cart items
  final List<Map<String, dynamic>> _cartItems = [];
  
  // Favorites
  final List<String> _favoriteShopIds = [];
  
  // Data lists
  final List<Product> _products = [];
  final List<Shop> _shops = [];
  final List<ProductCategory> _categories = [];
  final List<UserAddress> _addresses = [];
  final List<Province> _provinces = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  // Current user
  User? _currentUser;
  
  // Getters
  Province? get selectedProvince => _selectedProvince;
  District? get selectedDistrict => _selectedDistrict;
  ProductCategory? get selectedCategory => _selectedCategory;
  bool get isGridView => _isGridView;
  String get viewMode => _viewMode;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get searchQuery => _searchQuery;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<String> get favoriteShopIds => _favoriteShopIds;
  List<Product> get products => _products;
  List<Shop> get shops => _shops;
  List<Shop> get nearbyShops => _shops.take(4).toList(); // Get first 4 shops as nearby
  List<ProductCategory> get categories => _categories;
  
  // Check if a shop is in favorites
  bool isShopFavorite(String shopId) => _favoriteShopIds.contains(shopId);
  
  // Get total items in cart
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  
  // Get cart total amount
  double get cartTotalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      return sum + (product.finalPrice * quantity);
    });
  }
  
  // Set selected province
  void setSelectedProvince(Province? province) {
    _selectedProvince = province;
    _selectedDistrict = null; // Reset district when province changes
    notifyListeners();
    
    // Load shops and products for the selected location
    if (province != null) {
      loadShopsAndProducts();
    }
  }
  
  // Set selected district
  void setSelectedDistrict(District? district) {
    _selectedDistrict = district;
    notifyListeners();
    
    // Reload shops and products with the new district filter
    if (_selectedProvince != null) {
      loadShopsAndProducts();
    }
  }
  
  // Set selected category
  void setSelectedCategory(ProductCategory? category) {
    _selectedCategory = category;
    notifyListeners();
    
    // Filter products by the selected category
    filterProducts();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    
    // Filter products based on search query
    filterProducts();
  }
  
  // Load initial data
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('Loading initial data...');
      
      // Reset data
      _products.clear();
      _shops.clear();
      _categories.clear();
      _addresses.clear();
      _provinces.clear();
      _currentPage = 1;
      
      // Load data from database
      print('Loading categories...');
      await _loadCategories();
      print('Categories loaded: ${_categories.length}');
      
      print('Loading products...');
      await _loadProducts();
      print('Products loaded: ${_products.length}');
      
      print('Loading shops...');
      await _loadShops();
      print('Shops loaded: ${_shops.length}');
      
      // Load provinces
      await _loadProvinces();
      
      // Only load user addresses if we have a user
      if (_currentUser != null) {
        print('Loading user addresses...');
        await _loadUserAddresses();
        print('User addresses loaded: ${_addresses.length}');
      }
      
      // Set default province if not set
      if (_selectedProvince == null && _provinces.isNotEmpty) {
        _selectedProvince = _provinces.first;
      }
      
      _isLoading = false;
      notifyListeners();
      
      print('Initial data loaded successfully');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error in loadInitialData: $e');
      rethrow;
    }
  }
  
  // Load provinces from database or API
  Future<void> _loadProvinces() async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if provinces table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='provinces'"
      );
      
      if (tables.isEmpty) {
        // Create provinces table if it doesn't exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS provinces (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            region TEXT,
            imageUrl TEXT
          )
        ''');
        
        // Insert default provinces if table was just created
        await _insertDefaultProvinces(db);
      }
      
      // Load provinces from database
      final List<Map<String, dynamic>> provinceMaps = await db.query('provinces');
      
      // Clear existing provinces and add loaded ones
      _provinces.clear();
      _provinces.addAll(provinceMaps.map((map) => Province.fromMap(map)));
      
      print('Loaded ${_provinces.length} provinces');
    } catch (e) {
      print('Error loading provinces: $e');
      rethrow;
    }
  }
  
  // Insert default provinces into the database
  Future<void> _insertDefaultProvinces(Database db) async {
    final defaultProvinces = [
      {'id': 1, 'name': 'กรุงเทพมหานคร', 'region': 'กลาง'},
      {'id': 2, 'name': 'สมุทรปราการ', 'region': 'กลาง'},
      {'id': 3, 'name': 'นนทบุรี', 'region': 'กลาง'},
      {'id': 4, 'name': 'ปทุมธานี', 'region': 'กลาง'},
      {'id': 5, 'name': 'พระนครศรีอยุธยา', 'region': 'กลาง'},
      {'id': 6, 'name': 'อ่างทอง', 'region': 'กลาง'},
      {'id': 7, 'name': 'ลพบุรี', 'region': 'กลาง'},
      {'id': 8, 'name': 'สิงห์บุรี', 'region': 'กลาง'},
      {'id': 9, 'name': 'ชัยนาท', 'region': 'กลาง'},
      {'id': 10, 'name': 'สระบุรี', 'region': 'กลาง'},
      // Add more provinces as needed
    ];
    
    try {
      final batch = db.batch();
      
      for (final province in defaultProvinces) {
        batch.insert('provinces', province);
      }
      
      await batch.commit(noResult: true);
      print('Inserted ${defaultProvinces.length} default provinces');
    } catch (e) {
      print('Error inserting default provinces: $e');
      rethrow;
    }
  }
  
  // Load more data for pagination
  Future<void> loadMoreData() async {
    if (_isLoadingMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      await loadShopsAndProducts(loadMore: true);
    } catch (e) {
      print('Error loading more data: $e');
      _currentPage--; // Revert page on error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  // Load categories
  Future<void> _loadCategories() async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if categories table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'"
      );
      
      if (tables.isEmpty) {
        print('Categories table does not exist yet');
        return;
      }
      
      final categories = await db.query('categories');
      
      _categories.clear();
      for (var category in categories) {
        try {
          _categories.add(ProductCategory.fromMap(category));
        } catch (e) {
          print('Error parsing category: $e');
        }
      }
      
      // If no categories, add some default ones
      if (_categories.isEmpty) {
        print('No categories found, adding default categories');
        await _addDefaultCategories();
        // Reload categories
        await _loadCategories();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }
  
  // Add default categories
  Future<void> _addDefaultCategories() async {
    try {
      final db = await _databaseHelper.database;
      
      final defaultCategories = [
        {'name': 'อาหารสด', 'icon': '🍜'},
        {'name': 'เครื่องดื่ม', 'icon': '☕'},
        {'name': 'ของใช้ในบ้าน', 'icon': '🏠'},
        {'name': 'เครื่องปรุง', 'icon': '🧂'},
        {'name': 'ขนมขบเคี้ยว', 'icon': '🍿'},
      ];
      
      for (var category in defaultCategories) {
        await db.insert('categories', {
          'name': category['name'],
          'icon': category['icon'],
          'isActive': 1,
        });
      }
    } catch (e) {
      print('Error adding default categories: $e');
    }
  }
  
  // Load products
  Future<void> _loadProducts() async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if products table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='products'"
      );
      
      if (tables.isEmpty) {
        print('Products table does not exist yet');
        return;
      }
      
      final products = await db.query('products');
      
      _products.clear();
      for (var product in products) {
        try {
          _products.add(Product.fromMap(product));
        } catch (e) {
          print('Error parsing product: $e');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
    }
  }
  
  // Load shops
  Future<void> _loadShops() async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if shops table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='shops'"
      );
      
      if (tables.isEmpty) {
        print('Shops table does not exist yet');
        return;
      }
      
      final shops = await db.query('shops');
      
      _shops.clear();
      for (var shopMap in shops) {
        try {
          _shops.add(Shop.fromMap(shopMap));
        } catch (e) {
          print('Error parsing shop: $e');
        }
      }
      
      // If no shops, add a default one for testing
      if (_shops.isEmpty) {
        print('No shops found, adding a default shop');
        await _addDefaultShop();
        // Reload shops
        await _loadShops();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading shops: $e');
    }
  }
  
  // Add a default shop for testing
  Future<void> _addDefaultShop() async {
    try {
      final db = await _databaseHelper.database;
      
      // First, check if we have a user to be the shop owner
      final users = await db.query('users', limit: 1);
      if (users.isEmpty) {
        print('No users found, cannot add default shop');
        return;
      }
      
      final userId = users.first['id'];
      
      await db.insert('shops', {
        'name': 'ร้านค้าตัวอย่าง',
        'description': 'นี่คือร้านค้าตัวอย่างสำหรับทดสอบระบบ',
        'address': '123 ถนนตัวอย่าง',
        'province': 'กรุงเทพมหานคร',
        'district': 'บางรัก',
        'subdistrict': 'สีลม',
        'postalCode': '10500',
        'phone': '0812345678',
        'email': 'example@shop.com',
        'logo': 'assets/images/shop_logo.png',
        'coverImage': 'assets/images/shop_cover.jpg',
        'isOpen': 1,
        'isVerified': 1,
        'rating': 4.5,
        'totalRatings': 10,
        'sellerId': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding default shop: $e');
    }
  }
  
  // Load user addresses
  Future<void> _loadUserAddresses() async {
    if (_currentUser == null) return;
    
    try {
      final db = await _databaseHelper.database;
      
      // Check if user_addresses table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_addresses'"
      );
      
      if (tables.isEmpty) {
        print('User addresses table does not exist yet');
        return;
      }
      
      final addresses = await db.query(
        'user_addresses',
        where: 'userId = ?',
        whereArgs: [_currentUser?.id],
        orderBy: 'isDefault DESC, createdAt DESC',
      );
      
      _addresses.clear();
      for (var address in addresses) {
        try {
          _addresses.add(UserAddress.fromMap(address));
        } catch (e) {
          print('Error parsing address: $e');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading user addresses: $e');
    }
  }
  
  // Load shops and products for the current location
  Future<void> loadShopsAndProducts({bool loadMore = false}) async {
    if (!loadMore) {
      _currentPage = 1;
      _products.clear();
      _shops.clear();
    }
    
    try {
      // In a real app, you would fetch shops and products from your database/API
      // based on the selected province/district and pagination
      
      // This is a temporary solution with mock data
      if (!loadMore) {
        // Mock shops data
        _shops.addAll(List.generate(10, (index) => Shop(
          id: 'shop_$index',
          sellerId: 'seller_$index',  // Added required sellerId
          name: 'ร้านค้าตัวอย่าง ${index + 1}',
          description: 'คำอธิบายร้านค้าตัวอย่าง ${index + 1}',
          address: 'ที่อยู่ตัวอย่าง',
          province: _selectedProvince?.name ?? 'จังหวัด',
          district: _selectedDistrict?.name ?? 'อำเภอ',
          latitude: 13.7563 + (index * 0.01),
          longitude: 100.5018 + (index * 0.01),
          phone: '0812345678',
          email: 'shop$index@example.com',
          logo: 'https://via.placeholder.com/150',
          coverImage: 'https://via.placeholder.com/800x300',
          isOpen: true,
          isVerified: index % 2 == 0,
          rating: 4.0 + (index * 0.2),
          totalRatings: 10 + index,
        )));
        
        // Mock products data
        _products.addAll(List.generate(20, (index) => Product(
          id: 'product_$index',
          shopId: 'shop_${index % 5}',
          sellerId: 'seller_${index % 5}',
          name: 'สินค้าตัวอย่าง ${index + 1}',
          description: 'คำอธิบายสินค้าตัวอย่าง ${index + 1}',
          price: 100.0 + (index * 10),
          originalPrice: 150.0 + (index * 10),
          discount: index % 3 == 0 ? 10.0 : 0.0,
          stock: 100,
          categoryId: _categories[index % _categories.length].id,
          subCategoryId: 'sub_${index % 3 + 1}',
          isAvailable: true,
          isFeatured: index % 5 == 0,
          images: ['https://via.placeholder.com/300'],
          viewCount: 100 + index,
          soldCount: 10 + index,
          rating: 4.0 + (index * 0.1),
          totalRatings: 5 + index,
        )));
      }
      
      // Apply filters
      filterProducts();
      
    } catch (e) {
      print('Error loading shops and products: $e');
    }
  }
  
  // Toggle between grid and list view
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }
  
  // Set the current view mode (products or shops)
  void setViewMode(String mode) {
    _isGridView = mode == 'products';
    notifyListeners();
  }
  
  // Filter products based on search query and selected category
  void filterProducts() {
    // In a real app, you would apply filters to your database query
    // based on selectedCategory and searchQuery
    notifyListeners();
  }
  
  // Add product to cart
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) {
      return (item['product'] as Product).id == product.id;
    });
    
    if (existingIndex >= 0) {
      // Update quantity if product already in cart
      _cartItems[existingIndex]['quantity'] += quantity;
    } else {
      // Add new item to cart
      _cartItems.add({
        'product': product,
        'quantity': quantity,
        'addedAt': DateTime.now(),
      });
    }
    
    notifyListeners();
  }
  
  // Remove product from cart
  void removeFromCart(Product product) {
    _cartItems.removeWhere((item) => (item['product'] as Product).id == product.id);
    notifyListeners();
  }
  
  // Update product quantity in cart
  void updateCartItemQuantity(Product product, int quantity) {
    final index = _cartItems.indexWhere((item) {
      return (item['product'] as Product).id == product.id;
    });
    
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['quantity'] = quantity;
      }
      notifyListeners();
    }
  }
  
  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
  
  // Toggle shop favorite status
  void toggleFavoriteShop(String shopId) {
    if (_favoriteShopIds.contains(shopId)) {
      _favoriteShopIds.remove(shopId);
    } else {
      _favoriteShopIds.add(shopId);
    }
    notifyListeners();
  }
  
  // Get recommended products (for home screen)
  Future<List<Product>> getRecommendedProducts() async {
    // TODO: Implement logic to get recommended products
    // This could be based on user's location, past purchases, etc.
    return [];
  }
  
  // Get popular shops (for home screen)
  Future<List<Shop>> getPopularShops() async {
    // TODO: Implement logic to get popular shops
    // This could be based on ratings, number of sales, etc.
    return [];
  }
  
  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId, {int limit = 20}) async {
    // TODO: Implement logic to get products by category
    return [];
  }
  
  // Get shops by category
  Future<List<Shop>> getShopsByCategory(String categoryId, {int limit = 20}) async {
    // TODO: Implement logic to get shops by category
    return [];
  }
  
  // Search products
  Future<List<Product>> searchProducts(String query, {String? categoryId}) async {
    // TODO: Implement product search logic
    return [];
  }
  
  // Search shops
  Future<List<Shop>> searchShops(String query, {String? categoryId}) async {
    // TODO: Implement shop search logic
    return [];
  }
  
  // Get shop details
  Future<Shop?> getShopDetails(String shopId) async {
    // TODO: Implement logic to get shop details
    return null;
  }
  
  // Get shop products
  Future<List<Product>> getShopProducts(String shopId, {String? categoryId}) async {
    // TODO: Implement logic to get products by shop
    return [];
  }
  
  // Get product details
  Future<Product?> getProductDetails(String productId) async {
    // TODO: Implement logic to get product details
    return null;
  }
  
  // Get related products
  Future<List<Product>> getRelatedProducts(String productId) async {
    // TODO: Implement logic to get related products
    return [];
  }
  
  // Get nearby shops based on current location
  Future<List<Shop>> getNearbyShops(LatLng location, {double radiusInKm = 5.0}) async {
    // TODO: Implement logic to get nearby shops
    return [];
  }
  
  // Get popular products
  Future<List<Product>> getPopularProducts({int limit = 20}) async {
    // TODO: Implement logic to get popular products
    return [];
  }
  
  // Get new arrivals
  Future<List<Product>> getNewArrivals({int limit = 20}) async {
    // TODO: Implement logic to get new arrivals
    return [];
  }
  
  // Get deals and discounts
  Future<List<Product>> getDealsAndDiscounts({int limit = 20}) async {
    // TODO: Implement logic to get products with discounts
    return [];
  }
}
