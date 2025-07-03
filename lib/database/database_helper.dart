// ignore_for_file: avoid_print

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqlite_ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart' show User;

extension DatabaseExt on Database {
  Future<int> getVersion() async => (await rawQuery('PRAGMA user_version')).first['user_version'] as int? ?? 0;
  Future<void> setVersion(int version) => execute('PRAGMA user_version = $version');
}

class DatabaseHelper {
  static final _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _databaseVersion = 3;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal(); // Constructor ไม่เรียก _initDatabase() ตรงๆ แล้ว

  Future<Database> get db async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future? get database => null;
  
  // ลบ Future<Database> get database => db; ที่ซ้ำซ้อนออก
  
  Future<List<Map<String, dynamic>>> getUsersWithEvents() async {
    try {
      final result = await (await db).rawQuery('''
        SELECT 
          users.id as userId,
          users.name as userName,
          users.email as userEmail,
          GROUP_CONCAT(events.content) as eventContents
        FROM users
        LEFT JOIN events ON users.id = events.userId
        GROUP BY users.id, users.name, users.email
      ''');

      return result.map((row) => {
        'userId': row['userId'],
        'userName': row['userName'],
        'userEmail': row['userEmail'],
        'events': row['eventContents']?.toString().split(',').where((s) => s.isNotEmpty).toList() ?? <String>[],
      }).toList();
    } catch (e) {
      debugPrint('Error getting users with events: $e');
      rethrow;
    }
  }
  
  Future<int> addUserEvent({required int userId, required String content, String? type}) async {
    try {
      return await insert('events', {
        'userId': userId,
        'content': content,
        'type': type,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding user event: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserEvents(int userId) async {
    try {
      return await query('events', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    } catch (e) {
      debugPrint('Error getting user events: $e');
      rethrow;
    }
  }

  // Close method is implemented below with a more specific implementation

  // Future<Database> get database async => db; // บรรทัดนี้ถูกลบออกไปแล้ว
  
  Future<void> _checkAndCreateTables() async {
    if (_database == null) return;
    
    try {
      final usersTable = await _database!.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      
      if (usersTable.isEmpty) {
        await _onCreate(_database!, 1);
      } else {
        final version = await _database!.getVersion();
        if (version < _databaseVersion) {
          await _onUpgrade(_database!, version, _databaseVersion);
        }
      }
    } catch (e) {
      debugPrint('Error checking/creating tables: $e');
      await _database!.close();
      final dbPath = path.join(await getDatabasesPath(), 'banbanshop.db');
      await deleteDatabase(dbPath);
      _database = await _initDatabase();
    }
  }

  Future<Database> _initDatabase() async {
    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqlite_ffi.sqfliteFfiInit();
        databaseFactory = sqlite_ffi.databaseFactoryFfi;
      }
      
      final dbPath = path.join(await getDatabasesPath(), 'banbanshop.db');
      
      if (!kIsWeb) {
        final directory = Directory(path.dirname(dbPath));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }
      
      final db = await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        singleInstance: true,
      );
      
      await _checkAndCreateTables();
      return db;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
  
  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
      final result = await db.rawQuery('PRAGMA foreign_keys');
      debugPrint('Foreign keys enabled: ${result.first['foreign_keys'] == 1}');
    } catch (e) {
      debugPrint('Error configuring database: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      final batch = db.batch();
      
      if (oldVersion < 2) {
        batch.execute('''
          CREATE TABLE IF NOT EXISTS events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            content TEXT NOT NULL,
            type TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      }
      
      if (oldVersion < 3) {
        try {
          batch.execute('ALTER TABLE users ADD COLUMN lastLogin TEXT');
        } catch (e) {
          debugPrint('Error adding lastLogin column: $e');
        }
      }
      
      await batch.commit(noResult: true);
      await db.setVersion(newVersion);
    } catch (e) {
      debugPrint('Error upgrading database: $e');
      rethrow;
    }
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    
    try {
      // Create users table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          phone TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          address TEXT,
          profileImage TEXT,
          idCardImage TEXT,
          role TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      
      // Create user_addresses table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS user_addresses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          recipientName TEXT NOT NULL,
          phoneNumber TEXT NOT NULL,
          addressLine1 TEXT NOT NULL,
          addressLine2 TEXT,
          province TEXT NOT NULL,
          district TEXT NOT NULL,
          subdistrict TEXT NOT NULL,
          postalCode TEXT NOT NULL,
          isDefault INTEGER DEFAULT 0,
          latitude REAL,
          longitude REAL,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create shops table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS shops(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sellerId INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          address TEXT NOT NULL,
          province TEXT NOT NULL,
          district TEXT,
          subdistrict TEXT,
          postalCode TEXT,
          latitude REAL,
          longitude REAL,
          phone TEXT NOT NULL,
          email TEXT,
          logo TEXT,
          coverImage TEXT,
          openTime TEXT,
          closeTime TEXT,
          isOpen INTEGER DEFAULT 1,
          isVerified INTEGER DEFAULT 0,
          rating REAL DEFAULT 0,
          totalRatings INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (sellerId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create categories table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          parentId INTEGER,
          icon TEXT,
          color TEXT,
          isActive INTEGER DEFAULT 1,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (parentId) REFERENCES categories (id) ON DELETE SET NULL
        )
      ''');
      
      // Create products table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shopId INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          originalPrice REAL,
          discount REAL,
          stock INTEGER DEFAULT 0,
          categoryId INTEGER NOT NULL,
          subCategoryId INTEGER,
          isAvailable INTEGER DEFAULT 1,
          isFeatured INTEGER DEFAULT 0,
          images TEXT,
          tags TEXT,
          viewCount INTEGER DEFAULT 0,
          soldCount INTEGER DEFAULT 0,
          rating REAL DEFAULT 0,
          totalRatings INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (shopId) REFERENCES shops (id) ON DELETE CASCADE,
          FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE,
          FOREIGN KEY (subCategoryId) REFERENCES categories (id) ON DELETE SET NULL
        )
      ''');
      
      // Create favorites table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
          UNIQUE(userId, productId)
        )
      ''');
      
      // Create cart_items table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS cart_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          quantity INTEGER DEFAULT 1,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
          UNIQUE(userId, productId)
        )
      ''');
      
      // Create orders table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderNumber TEXT NOT NULL,
          userId INTEGER NOT NULL,
          shopId INTEGER NOT NULL,
          addressId INTEGER NOT NULL,
          status TEXT NOT NULL,
          subtotal REAL NOT NULL,
          shippingFee REAL NOT NULL,
          discount REAL DEFAULT 0,
          total REAL NOT NULL,
          paymentMethod TEXT,
          paymentStatus TEXT,
          notes TEXT,
          trackingNumber TEXT,
          deliveredAt TEXT,
          cancelledAt TEXT,
          cancelledReason TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (shopId) REFERENCES shops (id) ON DELETE CASCADE,
          FOREIGN KEY (addressId) REFERENCES user_addresses (id) ON DELETE CASCADE
        )
      ''');
      
      // Create order_items table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS order_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          productName TEXT NOT NULL,
          productPrice REAL NOT NULL,
          quantity INTEGER NOT NULL,
          subtotal REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products (id) ON DELETE SET NULL
        )
      ''');
      
      // Create notifications table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          referenceId INTEGER,
          isRead INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create events table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS events(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          content TEXT NOT NULL,
          type TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for better performance
      batch.execute('CREATE INDEX IF NOT EXISTS idx_products_shopId ON products(shopId)');
      batch.execute('CREATE INDEX IF NOT EXISTS idx_products_categoryId ON products(categoryId)');
      batch.execute('CREATE INDEX IF NOT EXISTS idx_orders_userId ON orders(userId)');
      batch.execute('CREATE INDEX IF NOT EXISTS idx_orders_shopId ON orders(shopId)');
      batch.execute('CREATE INDEX IF NOT EXISTS idx_order_items_orderId ON order_items(orderId)');
      
      // Commit the batch
      await batch.commit(noResult: true);
      
      // Insert default admin user
      await _insertDefaultData(db);
      
      // Set the database version
      await db.setVersion(version);
      
    } catch (e) {
      print('Error creating tables: $e');
      rethrow;
    }
  }

  // Insert default data
  Future<void> _insertDefaultData(Database db) async {
    try {
      // Insert default admin user if not exists
      final adminExists = await db.rawQuery('SELECT 1 FROM users WHERE email = ?', ['admin@banbanshop.com']);
      if (adminExists.isEmpty) {
        await db.insert('users', {
          'name': 'Admin',
          'email': 'admin@banbanshop.com',
          'password': 'hashed_password_here', // In a real app, hash the password
          'phone': '0812345678',
          'role': 'admin',
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Check if categories already exist
      final categoriesCount = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final count = categoriesCount.first['count'] as int? ?? 0;
      
      if (count == 0) {
        // Insert default categories
        final categories = [
          {'name': 'อาหารสด', 'icon': '🍜', 'isActive': 1},
          {'name': 'เครื่องดื่ม', 'icon': '☕', 'isActive': 1},
          {'name': 'ของใช้ในบ้าน', 'icon': '🏠', 'isActive': 1},
          {'name': 'เครื่องปรุง', 'icon': '🧂', 'isActive': 1},
          {'name': 'ขนมขบเคี้ยว', 'icon': '🍿', 'isActive': 1},
        ];
        
        for (var category in categories) {
          await db.insert('categories', {
            'name': category['name'],
            'icon': category['icon'],
            'isActive': category['isActive'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error inserting default data: $e');
      rethrow;
    }
  }

  // User related methods
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await this.db;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // Removed duplicate updateUser method - keeping the one that uses User

  Future<void> deleteUser(int id) async {
    final db = await this.db;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Shop related methods
  Future<int> insertShop(Map<String, dynamic> shop) async {
    return await insert('shops', shop);
  }

  Future<Map<String, dynamic>?> getShop(int id) async {
    final result = await query(
      'shops',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getShopsBySeller(int sellerId) async {
    return await query(
      'shops',
      where: 'sellerId = ?',
      whereArgs: [sellerId],
    );
  }

  Future<void> updateShop(Map<String, dynamic> shop) async {
    await update(
      'shops',
      shop,
      where: 'id = ?',
      whereArgs: [shop['id']],
    );
  }

  // Product related methods
  Future<int> insertProduct(Map<String, dynamic> product) async {
    return await insert('products', product);
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    final result = await query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getProductsByShop(int shopId, {int? categoryId, int limit = 20, int offset = 0}) async {
    final db = await this.db;
    String where = 'shopId = ?';
    List<dynamic> whereArgs = [shopId];

    if (categoryId != null) {
      where += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }

    return await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'isFeatured DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    await update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  // Category methods
  Future<List<Map<String, dynamic>>> getCategories({int? parentId}) async {
    final db = await this.db;
    if (parentId != null) {
      return await db.query(
        'categories',
        where: 'parentId = ?',
        whereArgs: [parentId],
      );
    } else {
      return await db.query('categories');
    }
  }

  // Cart methods
  Future<Map<String, dynamic>> getOrCreateCart(int userId, int shopId) async {
    final db = await this.db;
    // Check if user already has an active cart for this shop
    final existingCarts = await db.query(
      'cart',
      where: 'userId = ? AND shopId = ?',
      whereArgs: [userId, shopId],
    );

    if (existingCarts.isNotEmpty) {
      return existingCarts.first;
    }

    // Create a new cart
    final newCart = {
      'userId': userId,
      'shopId': shopId,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final id = await db.insert('cart', newCart);
    return {...newCart, 'id': id};
  }

  Future<Map<String, dynamic>> addToCart(int cartId, int productId, {int quantity = 1, int? variantId, String? notes}) async {
    final db = await this.db;
    
    // Check if product already exists in cart
    final existingItems = await db.query(
      'cart_items',
      where: 'cartId = ? AND productId = ? AND variantId ${variantId != null ? '= ?' : 'IS NULL'}',
      whereArgs: [cartId, productId, if (variantId != null) variantId],
    );

    if (existingItems.isNotEmpty) {
      // Update quantity if item already in cart
      final existingItem = existingItems.first;
      final newQuantity = (existingItem['quantity'] as int) + quantity;
      
      await db.update(
        'cart_items',
        {
          'quantity': newQuantity,
          'notes': notes ?? existingItem['notes'],
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existingItem['id']],
      );
      
      return await db.query(
        'cart_items',
        where: 'id = ?',
        whereArgs: [existingItem['id']],
      ).then((value) => value.first);
    } else {
      // Add new item to cart
      final newItem = {
        'cartId': cartId,
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'notes': notes,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final id = await db.insert('cart_items', newItem);
      return {...newItem, 'id': id};
    }
  }

  // Order methods
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final db = await this.db;
    
    // Start transaction
    await db.execute('BEGIN TRANSACTION');
    
    try {
      // Insert order
      final orderId = await db.insert('orders', orderData);
      
      // Insert order items
      final List<Map<String, dynamic>> items = orderData['items'];
      for (var item in items) {
        item['orderId'] = orderId;
        await db.insert('order_items', item);
        
        // Update product stock
        if (item['variantId'] != null) {
          await db.rawUpdate(
            'UPDATE product_variants SET stock = stock - ? WHERE id = ? AND stock >= ?',
            [item['quantity'], item['variantId'], item['quantity']]
          );
        } else {
          await db.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?',
            [item['quantity'], item['productId'], item['quantity']]
          );
        }
      }
      
      // Clear cart
      await db.delete(
        'cart_items',
        where: 'cartId = ?',
        whereArgs: [orderData['cartId']],
      );
      
      // Commit transaction
      await db.execute('COMMIT');
      
      // Return the created order
      final order = await db.query(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
      
      order[0]['items'] = await db.query(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      
      return order.first;
    } catch (e) {
      // Rollback on error
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  // Search methods
  Future<List<Map<String, dynamic>>> searchProducts(String query, {int? categoryId, String? location, int limit = 20, int offset = 0}) async {
    final db = await this.db;
    String where = 'isAvailable = 1';
    List<dynamic> whereArgs = [];
    
    if (query.isNotEmpty) {
      where += ' AND (name LIKE ? OR description LIKE ?)';
      whereArgs.addAll(['%$query%', '%$query%']);
    }
    
    if (categoryId != null) {
      where += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }
    
    if (location != null && location.isNotEmpty) {
      where += ' AND (address LIKE ? OR province LIKE ? OR district LIKE ? OR subdistrict LIKE ?)';
      whereArgs.addAll(['%$location%', '%$location%', '%$location%', '%$location%']);
    }
    
    return await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'isFeatured DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Utility methods
  Future<T> transaction<T>(Future<T> Function(Database) action) async {
    final db = await this.db;
    return await db.transaction<T>((txn) async {
      return await action(txn as Database);
    });
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await this.db;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await this.db;
    return await db.rawUpdate(sql, arguments);
  }

  // Close the database when done
  Future<void> close() async {
    final db = await this.db;
    await db.close();
  }
  
  // Address related methods
  Future<int> insertAddress(Map<String, dynamic> address) async {
    final db = await this.db;
    return await db.insert('user_addresses', address);
  }
  
  Future<List<Map<String, dynamic>>> getUserAddresses(int userId) async {
    final db = await this.db;
    return await db.query(
      'user_addresses',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'isDefault DESC, id DESC',
    );
  }
  
  Future<int> updateAddress(Map<String, dynamic> address) async {
    final db = await this.db;
    return await db.update(
      'user_addresses',
      address,
      where: 'id = ? AND userId = ?',
      whereArgs: [address['id'], address['userId']],
    );
  }
  
  Future<int> deleteAddress(int id, int userId) async {
    final db = await this.db;
    return await db.delete(
      'user_addresses',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
  
  // Wishlist methods
  Future<bool> isProductInWishlist(int userId, int productId) async {
    final db = await this.db;
    final result = await db.query(
      'wishlist',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
    return result.isNotEmpty;
  }

  Future<bool> isUserLoggedIn() async {
    final db = await this.db;
    final result = await db.query(
      'users',
      where: 'isLoggedIn = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Gets the currently logged-in user from the database
  Future<User?> getCurrentUser() async {
    try {
      final db = await this.db;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'isLoggedIn = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Updates a user in the database
  Future<bool> updateUser(User user) async {
    try {
      final db = await this.db;
      final rowsAffected = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Logs out the current user by setting isLoggedIn to 0 for all users
  Future<bool> logout() async {
    try {
      final db = await this.db;
      await db.update(
        'users',
        {'isLoggedIn': 0},
        where: 'isLoggedIn = ?',
        whereArgs: [1],
      );
      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }
  
  Future<int> toggleWishlist(int userId, int productId) async {
    final db = await this.db;
    final isInWishlist = await isProductInWishlist(userId, productId);
    
    if (isInWishlist) {
      return await db.delete(
        'wishlist',
        where: 'userId = ? AND productId = ?',
        whereArgs: [userId, productId],
      );
    } else {
      return await db.insert('wishlist', {
        'userId': userId,
        'productId': productId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }
  
  Future<List<Map<String, dynamic>>> getWishlist(int userId) async {
    final db = await this.db;
    return await db.rawQuery('''
      SELECT p.* FROM products p
      INNER JOIN wishlist w ON p.id = w.productId
      WHERE w.userId = ?
      ORDER BY w.createdAt DESC
    ''', [userId]);
  }
  
  // Review methods
  Future<int> createReview(Map<String, dynamic> review) async {
    final db = await this.db;
    return await db.insert('reviews', review);
  }
  
  Future<List<Map<String, dynamic>>> getProductReviews(int productId, {int limit = 10, int offset = 0}) async {
    final db = await this.db;
    return await db.query(
      'reviews',
      where: 'productId = ? AND status = ?',
      whereArgs: [productId, 'approved'],
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
  }
  
  // Notification methods
  Future<List<Map<String, dynamic>>> getUnreadNotifications(int userId, {int limit = 20}) async {
    final db = await this.db;
    return await db.query(
      'notifications',
      where: 'userId = ? AND isRead = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
  }
  
  Future<int> markNotificationAsRead(int notificationId, int userId) async {
    final db = await this.db;
    return await db.update(
      'notifications',
      {
        'isRead': 1,
        'readAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [notificationId, userId],
    );
  }
  
  // Settings methods
  Future<Map<String, dynamic>> getSettings() async {
    final db = await this.db;
    final settings = await db.query('settings');
    
    final result = <String, dynamic>{};
    for (var setting in settings) {
      if (setting['isPublic'] == 1) {
        final key = setting['key'] as String?;
        final value = setting['value'] as String?;
        if (key != null && value != null) {
          result[key] = value;
        }
      }
    }
    
    return result;
  }
  
  Future<int> updateSetting(String key, String value) async {
    final db = await this.db;
    return await db.update(
      'settings',
      {
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: [key],
    );
  }
  
  // Analytics methods
  Future<Map<String, dynamic>> getShopAnalytics(int shopId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await this.db;
    
    // Get total products
    final totalProducts = (await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE shopId = ?',
      [shopId],
    )).first['count'] as int;
    
    // Get total orders
    var where = 'shopId = ?';
    var whereArgs = <Object?>[shopId];
    
    if (startDate != null) {
      where += ' AND createdAt >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where += ' AND createdAt <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final totalOrdersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE $where',
      whereArgs,
    );
    final totalOrders = (totalOrdersResult.first['count'] as int?) ?? 0;
    
    // Get total revenue
    final totalRevenue = (await db.rawQuery(
      'SELECT COALESCE(SUM(totalAmount), 0) as total FROM orders WHERE status != ? AND $where',
      ['cancelled', ...whereArgs],
    )).first['total'] as double;
    
    // Get top selling products
    final topProducts = await db.rawQuery('''
      SELECT p.id, p.name, p.images, SUM(oi.quantity) as totalQuantity, SUM(oi.subtotal) as totalAmount
      FROM order_items oi
      JOIN products p ON oi.productId = p.id
      JOIN orders o ON oi.orderId = o.id
      WHERE o.shopId = ? AND o.status != ?
      GROUP BY p.id, p.name, p.images
      ORDER BY totalQuantity DESC
      LIMIT 5
    ''', [shopId, 'cancelled']);
    
    // Get order status counts
    final orderStatusCounts = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM orders
      WHERE shopId = ?
      GROUP BY status
    ''', [shopId]);
    
    return {
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'topProducts': topProducts,
      'orderStatusCounts': orderStatusCounts,
    };
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database; // ใช้ getter database ที่ถูกต้อง
    try {
      return await db.insert(table, data);
    } catch (e) {
      print('Error inserting into $table: $e');
      rethrow;
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database; // ใช้ getter database ที่ถูกต้อง
    try {
      return await db.update(
        table,
        data,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('Error updating $table: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database; // ใช้ getter database ที่ถูกต้อง
    try {
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database; // ใช้ getter database ที่ถูกต้อง
    try {
      return await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('Error deleting from $table: $e');
      rethrow;
    }
  }
}