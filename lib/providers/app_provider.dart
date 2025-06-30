import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:banbanshop/database/repository.dart';
import 'package:banbanshop/models/order_model.dart';
import 'package:banbanshop/models/product_model.dart';
import 'package:banbanshop/models/user_model.dart';

class AppProvider with ChangeNotifier {
  final Repository _repository = Repository();
  User? _currentUser;
  List<Product> _products = [];
  List<Order> _userOrders = [];
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  List<Product> get products => _products;
  List<Order> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // User methods
  Future<void> loadUserFromPrefs(SharedPreferences prefs) async {
    try {
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromMap(userMap);
        await _loadUserData();
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
    }
  }
  
  // Check if current user is a seller
  bool get isSeller => _currentUser?.role == UserRole.seller;
  
  // Check if current user is an admin
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> _saveUserToPrefs() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(_currentUser!.toMap()));
    }
  }

  Future<bool> login(String email, String password) async {
    debugPrint('LOGIN attempt: email=$email password=$password');
    _setLoading(true);
    try {
      final user = await _repository.getUserByEmail(email.trim());
      debugPrint('DB returned user: ${user?.toMap()}');
      if (user != null && user.password == password.trim()) {
        if (!user.isActive) {
          _setLoading(false);
          throw Exception('บัญชีของคุณถูกระงับ กรุณาติดต่อผู้ดูแลระบบ');
        }
        
        _currentUser = user;
        await _saveUserToPrefs();
        await _loadUserData();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> register(String email, String password, String name, String phone, {bool isSeller = false}) async {
    _setLoading(true);
    try {
      // Check if user already exists
      final existingUser = await _repository.getUserByEmail(email);
      if (existingUser != null) {
        _setLoading(false);
        return false; // User already exists
      }
      
      // Create new user
      final user = User(
        id: 0, // Will be set by the database
        name: name,
        email: email,
        phone: phone,
        password: password, // In a real app, this should be hashed
        role: isSeller ? UserRole.seller : UserRole.customer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final userId = await _repository.insertUser(user);
      if (userId > 0) {
        _currentUser = user.copyWith(id: userId);
        await _saveUserToPrefs();
        await _loadUserData();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _userOrders = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }

  // Product methods
  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      _products = await _repository.getAllProducts();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> addProduct(Product product, {File? imageFile}) async {
    _setLoading(true);
    try {
      await _repository.insertProduct(product, imageFile: imageFile);
      await loadProducts(); // Refresh the product list
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<void> updateProduct(Product product, {File? imageFile}) async {
    _setLoading(true);
    try {
      await _repository.updateProduct(product, imageFile: imageFile);
      await loadProducts(); // Refresh the product list
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<void> removeProduct(int productId, {String? imagePath}) async {
    _setLoading(true);
    try {
      await _repository.deleteProduct(productId, imagePath: imagePath);
      await loadProducts(); // Refresh the product list
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Order methods
  Future<void> placeOrder(Order order, List<OrderItem> items) async {
    _setLoading(true);
    try {
      await _repository.createOrder(order, items);
      await _loadUserOrders();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Private methods
  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      if (isSeller) {
        // For sellers, load only their products
        _products = await _repository.getProductsBySellerId(_currentUser!.id!);
      } else {
        // For customers, load all available products
        _products = await _repository.getAvailableProducts();
      }
      
      // Load user's orders
      _userOrders = await _repository.getUserOrders(_currentUser!.id!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserOrders() async {
    if (_currentUser != null) {
      _userOrders = await _repository.getUserOrders(_currentUser!.id!);
      notifyListeners();
    }
  }
  
  // Update user profile
  Future<void> updateUser(User user, {File? profileImage}) async {
    try {
      _setLoading(true);
      
      // Handle profile image upload if provided
      String? imagePath;
      if (profileImage != null) {
        // Save the image to local storage
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await profileImage.copy('${appDir.path}/$fileName');
        imagePath = savedImage.path;
      }
      
      // Update user with new image path if available
      final updatedUser = imagePath != null
          ? user.copyWith(profileImage: imagePath)
          : user;
      
      // Update in database
      await _repository.updateUser(updatedUser);
      
      // Update current user in memory
      _currentUser = updatedUser;
      
      // Save to SharedPreferences
      await _saveUserToPrefs();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      notifyListeners();
    }
  }

  // Cleanup
  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }
}
