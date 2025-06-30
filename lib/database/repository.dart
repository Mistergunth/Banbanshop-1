import 'dart:io';
import 'package:banbanshop/database/database_helper.dart';
import 'package:banbanshop/models/order_model.dart';
import 'package:banbanshop/models/product_model.dart';
import 'package:banbanshop/models/user_model.dart';
import 'package:banbanshop/utils/file_utils.dart';

class Repository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // User operations
  Future<int> insertUser(User user) async {
    return await _dbHelper.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
  
  Future<void> updateUser(User user) async {
    await _dbHelper.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Product operations
  Future<int> insertProduct(Product product, {File? imageFile}) async {
    final productMap = product.toMap();
    
    if (imageFile != null) {
      // Save image to local storage and update the path
      final imagePath = await FileUtils.saveImageToLocal(imageFile);
      productMap['imagePath'] = imagePath;
    }
    
    // Ensure sellerId is set
    if (product.sellerId == 0) {
      throw Exception('Seller ID is required');
    }
    
    return await _dbHelper.insert('products', productMap);
  }
  
  Future<void> deleteProduct(int productId, {String? imagePath}) async {
    // Delete the product from database
    await _dbHelper.delete('products', where: 'id = ?', whereArgs: [productId]);
    
    // Delete the associated image file if it exists
    if (imagePath != null) {
      await FileUtils.deleteLocalFile(imagePath);
    }
  }
  
  Future<void> updateProduct(Product product, {File? imageFile}) async {
    final productMap = product.toMap();
    
    if (imageFile != null) {
      // Delete old image if it exists
      if (product.imagePath != null) {
        await FileUtils.deleteLocalFile(product.imagePath!);
      }
      // Save new image and update the path
      final imagePath = await FileUtils.saveImageToLocal(imageFile);
      productMap['imagePath'] = imagePath;
    }
    
    await _dbHelper.update(
      'products',
      productMap,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<List<Product>> getAllProducts() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  /// Get products that are marked as available (in stock)
  Future<List<Product>> getAvailableProducts() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'products',
      where: 'quantity > 0',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  /// Get products by seller ID
  Future<List<Product>> getProductsBySellerId(int sellerId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'products',
      where: 'sellerId = ?',
      whereArgs: [sellerId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProduct(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Order operations
  Future<int> createOrder(Order order, List<OrderItem> items) async {
    final db = await _dbHelper.database;
    late int orderId;
    
    await db.transaction((txn) async {
      // Insert the order
      orderId = await txn.insert('orders', order.toMap());
      
      // Insert order items
      for (var item in items) {
        await txn.insert('order_items', {
          ...item.toMap(),
          'orderId': orderId,
          'id': null, // Let SQLite auto-generate the ID
        });
      }
    });
    
    return orderId;
  }

  Future<List<Order>> getUserOrders(int userId) async {
    final List<Map<String, dynamic>> orderMaps = await _dbHelper.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'orderDate DESC',
    );

    final List<Order> orders = [];
    
    for (var orderMap in orderMaps) {
      final order = Order.fromMap(orderMap);
      final items = await getOrderItems(order.id!);
      orders.add(Order(
        id: order.id,
        userId: order.userId,
        totalAmount: order.totalAmount,
        status: order.status,
        shippingAddress: order.shippingAddress,
        orderDate: order.orderDate,
        items: items,
      ));
    }
    
    return orders;
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final List<Map<String, dynamic>> itemMaps = await _dbHelper.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );

    final List<OrderItem> items = [];
    
    for (var itemMap in itemMaps) {
      final item = OrderItem.fromMap(itemMap);
      final product = await getProduct(item.productId);
      items.add(OrderItem(
        id: item.id,
        orderId: item.orderId,
        productId: item.productId,
        quantity: item.quantity,
        price: item.price,
        product: product,
      ));
    }
    
    return items;
  }

  // Close the database connection
  Future<void> close() async {
    await _dbHelper.close();
  }
}
