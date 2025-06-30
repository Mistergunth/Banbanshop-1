import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'database/database_helper.dart';
import 'database/repository.dart';
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/category_model.dart';
import 'providers/app_provider.dart';
import 'providers/buyer_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/buyer/location_selection_screen.dart';
import 'screens/buyer/buyer_home_screen.dart';
import 'screens/seller/seller_dashboard_screen.dart';
import 'screens/seller/product_management_screen.dart';
import 'screens/seller/product_edit_screen.dart';
import 'screens/admin/user_events_screen.dart';

void main() async {
  try {
    print('Starting app initialization...');
    
    // This is a desktop-only version
    if (kIsWeb) {
      // This should not happen as we're running in desktop mode
      throw UnsupportedError('Web platform is not supported. Please run the desktop version.');
    }
    
    // For desktop platforms
    try {
      print('Initializing FFI for desktop...');
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    } catch (e) {
      print('Error initializing FFI: $e');
      // Continue without FFI, the app will use the default SQLite implementation
    }
    
    WidgetsFlutterBinding.ensureInitialized();
    print('Widgets binding initialized');
    
    try {
      // Initialize the database
      print('Initializing database...');
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database; // This will create the database if it doesn't exist
      print('Database initialized');
      
      // Verify database is open
      if (db.isOpen) {
        print('Database is open');
        // Create test accounts if they don't exist
        print('Creating test accounts...');
        try {
          await _createTestAccounts(db);
          print('Test accounts created');
        } catch (e) {
          print('Error in _createTestAccounts: $e');
          rethrow;
        }
      } else {
        print('ERROR: Database is not open!');
      }
    } catch (e) {
      print('FATAL ERROR initializing database: $e');
      // Re-throw to prevent app from starting with broken DB
      rethrow;
    }
    
    // Initialize shared preferences
    print('Initializing shared preferences...');
    final prefs = await SharedPreferences.getInstance();
    print('Shared preferences initialized');
    
    // Initialize providers
    print('Initializing providers...');
    final appProvider = AppProvider()..loadUserFromPrefs(prefs);
    final buyerProvider = BuyerProvider();
    
    // Initialize BuyerProvider
    try {
      print('Initializing BuyerProvider...');
      await buyerProvider.initialize();
      print('BuyerProvider initialized successfully');
    } catch (e) {
      print('Error initializing BuyerProvider: $e');
      // Continue anyway, the provider will handle the error state
    }
    
    print('Running the app...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appProvider),
          ChangeNotifierProvider.value(value: buyerProvider),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('Stack trace: $stackTrace');
    // Run the app anyway with error UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error initializing the app. Please try again.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Show error message
                    print('Error: Could not restart the application. Please close and reopen it.');
                    // We can't show a dialog here since we don't have a valid context
                    // Just print to console and let the user know they need to restart
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บ้านบ้านช้อป',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.kanit().fontFamily,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.blue,
          secondary: Colors.orange,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: GoogleFonts.notoSansThaiTextTheme(
          Theme.of(context).textTheme,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E88E5),
            side: const BorderSide(color: Color(0xFF1E88E5)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E88E5),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
      ],
      home: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          if (appProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (appProvider.currentUser == null) {
            return const LoginScreen();
          }
          
          // For customers, show location selection if not set, otherwise show buyer home
          if (appProvider.currentUser!.role == UserRole.customer) {
            return Consumer<BuyerProvider>(
              builder: (context, buyerProvider, _) {
                // If province is not selected, show location selection
                if (buyerProvider.selectedProvince == null) {
                  return const LocationSelectionScreen();
                }
                // Otherwise show buyer home
                return const BuyerHomeScreen();
              },
            );
          }
          
          // For sellers, show seller dashboard
          if (appProvider.currentUser!.role == UserRole.seller) {
            return const SellerDashboardScreen();
          }
          
          // Default to home screen for other roles
          return const HomeScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        
        // Buyer routes
        '/buyer/location': (context) => const LocationSelectionScreen(),
        '/buyer/home': (context) => const BuyerHomeScreen(),
        
        // Admin routes
        '/admin/events': (context) => const UserEventsScreen(),
        // TODO: Add more buyer routes (product detail, shop detail, cart, etc.)
        
        // Seller routes
        '/seller/dashboard': (context) => const SellerDashboardScreen(),
        '/seller/products': (context) => const ProductManagementScreen(),
        '/seller/products/edit': (context) => const ProductEditScreen(),
        // TODO: Add more seller routes (orders, analytics, etc.)
      },
    );
  }
}

// Create test accounts if they don't exist
Future<void> _createTestAccounts(Database db) async {
  debugPrint('=== STARTING test account creation ===');
  try {
    // List of test accounts
    final testAccounts = [
      // Buyer accounts
      {
        'name': 'ผู้ซื้อ 1',
        'email': 'buyer1@example.com',
        'password': 'buyer1234',
        'phone': '0812345678',
        'address': '123/4 ถนนสุขุมวิท แขวงคลองเตย เขตคลองเตย กรุงเทพฯ 10110',
        'role': 'buyer',
        'isActive': 1,
      },
      {
        'name': 'ผู้ซื้อ 2',
        'email': 'buyer2@example.com',
        'password': 'buyer1234',
        'phone': '0822222222',
        'address': '456/7 ถนนรัชดาภิเษก แขวงดินแดง เขตดินแดง กรุงเทพฯ 10400',
        'role': 'buyer',
        'isActive': 1,
      },
      
      // Seller accounts
      {
        'name': 'ร้านค้าชุมชน 1',
        'email': 'seller1@example.com',
        'password': 'seller1234',
        'phone': '0833333333',
        'address': '789 หมู่ 5 ตำบลบางพูด อำเภอปากเกร็ด จังหวัดนนทบุรี 11120',
        'idCardImage': 'assets/images/id_card_sample.jpg',
        'role': 'seller',
        'isActive': 1,
      },
      {
        'name': 'ร้านค้าชุมชน 2',
        'email': 'seller2@example.com',
        'password': 'seller1234',
        'phone': '0844444444',
        'address': '321 หมู่ 9 ตำบลบางรักพัฒนา อำเภอบางบัวทอง จังหวัดนนทบุรี 11110',
        'idCardImage': 'assets/images/id_card_sample.jpg',
        'role': 'seller',
        'isActive': 1,
      },
      
      // Admin account
      {
        'name': 'ผู้ดูแลระบบ',
        'email': 'admin@example.com',
        'password': 'admin1234',
        'phone': '0800000000',
        'address': '999 หมู่ 1 ตำบลในเมือง อำเภอเมือง จังหวัดนนทบุรี 11000',
        'role': 'admin',
        'isActive': 1,
      },
    ];

    for (var account in testAccounts) {
      // Insert or ignore if already exists
      debugPrint('Inserting user: ${account['email']}');
      final result = await db.insert(
        'users',
        {
          'name': account['name'],
          'email': account['email'],
          'password': account['password'],
          'phone': account['phone'],
          'address': account['address'],
          'role': account['role'],
          'isActive': account['isActive'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      debugPrint('  -> Insert result for ${account['email']}: $result');
    }
    
    // Verify the users were inserted
    final users = await db.query('users');
    debugPrint('=== USERS IN DATABASE ===');
    for (var user in users) {
      debugPrint('${user['email']} (${user['role']})');
    }
    debugPrint('=========================');
    
    // Add test events for users
    debugPrint('=== ADDING TEST EVENTS ===');
    try {
      final events = await db.query('events');
      if (events.isEmpty) {
        // Get all users
        final allUsers = await db.query('users');
        
        for (var user in allUsers) {
          final userId = user['id'] as int;
          final userName = user['name'] as String;
          final userRole = user['role'] as String;
          
          // Add login event
          await db.insert('events', {
            'userId': userId,
            'content': '$userName ($userRole) logged in',
            'type': 'login',
            'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          });
          
          // Add some random events based on user role
          if (userRole == 'buyer') {
            await db.insert('events', {
              'userId': userId,
              'content': '$userName viewed products',
              'type': 'activity',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
            });
            
            await db.insert('events', {
              'userId': userId,
              'content': '$userName added item to cart',
              'type': 'cart',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            });
          } 
          else if (userRole == 'seller') {
            await db.insert('events', {
              'userId': userId,
              'content': '$userName added a new product',
              'type': 'product',
              'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            });
            
            await db.insert('events', {
              'userId': userId,
              'content': '$userName updated shop information',
              'type': 'shop',
              'createdAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
            });
          } 
          else if (userRole == 'admin') {
            await db.insert('events', {
              'userId': userId,
              'content': '$userName viewed user reports',
              'type': 'admin',
              'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            });
            
            await db.insert('events', {
              'userId': userId,
              'content': '$userName performed system maintenance',
              'type': 'admin',
              'createdAt': DateTime.now().subtract(const Duration(hours: 2, minutes: 15)).toIso8601String(),
            });
          }
        }
        debugPrint('Added test events for all users');
      } else {
        debugPrint('Test events already exist');
      }
    } catch (e) {
      debugPrint('Error adding test events: $e');
    }
  } catch (e) {
    debugPrint('Error creating test accounts: $e');
  }
}

// Old HomePage class has been removed as it's no longer needed.
// The app now uses the LoginScreen as the initial route and HomeScreen after login.