import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/seller_profile.dart';
import '../../models/shop_model.dart';
import 'shop_management_screen.dart';
import 'product_management_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_account_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  SellerProfile? _sellerProfile;
  Shop? _shop;
  bool _isLoading = true;
  int _orderCount = 0;
  int _productCount = 0;
  double _monthlyEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/seller/login');
        }
        return;
      }

      // Load seller profile
      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      if (sellerDoc.exists) {
        setState(() {
          _sellerProfile = SellerProfile.fromJson(sellerDoc.data()!..['id'] = sellerDoc.id);
        });

        // Load shop data if exists
        final shopQuery = await _firestore
            .collection('shops')
            .where('sellerId', isEqualTo: user.uid)
            .limit(1)
            .get();
            
        if (shopQuery.docs.isNotEmpty) {
          setState(() {
            _shop = Shop.fromJson(shopQuery.docs.first.data()..['id'] = shopQuery.docs.first.id);
          });
        }

        // Load order count
        final orderCount = await _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .count()
            .get();
            
        // Load product count
        final productCount = await _firestore
            .collection('products')
            .where('sellerId', isEqualTo: user.uid)
            .count()
            .get();
            
        // Load monthly earnings (example)
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final orders = await _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
            .get();
            
        double earnings = 0.0;
        for (var doc in orders.docs) {
          earnings += (doc.data()['totalAmount'] as num).toDouble();
        }

        if (mounted) {
          setState(() {
            _orderCount = orderCount.count ?? 0;
            _productCount = productCount.count ?? 0;
            _monthlyEarnings = earnings;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลผู้ขาย')),
          );
          Navigator.pushReplacementNamed(context, '/seller/register');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้ขาย'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSellerData,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                child: Icon(
                                  _shop != null ? Icons.store : Icons.person,
                                  size: 30,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _shop?.name ?? 'ร้านค้าของคุณ',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _sellerProfile?.email ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_shop == null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_business),
                                label: const Text('สร้างร้านค้า'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ShopManagementScreen(),
                                    ),
                                  ).then((_) => _loadSellerData());
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        title: 'คำสั่งซื้อทั้งหมด',
                        value: _orderCount.toString(),
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        title: 'สินค้าทั้งหมด',
                        value: _productCount.toString(),
                        icon: Icons.inventory,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        context,
                        title: 'รายได้เดือนนี้',
                        value: '฿${_monthlyEarnings.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        title: 'การจัดอันดับ',
                        value: _shop?.rating?.toStringAsFixed(1) ?? 'N/A',
                        icon: Icons.star,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  const Text(
                    'เมนูจัดการร้านค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildActionButton(
                        context,
                        title: 'จัดการสินค้า',
                        icon: Icons.inventory,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        title: 'จัดการคำสั่งซื้อ',
                        icon: Icons.receipt_long,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SellerOrdersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        title: 'จัดการร้านค้า',
                        icon: Icons.store,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShopManagementScreen(),
                            ),
                          ).then((_) => _loadSellerData());
                        },
                      ),
                      _buildActionButton(
                        context,
                        title: 'บัญชีผู้ใช้',
                        icon: Icons.person,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SellerAccountScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    _shop != null ? Icons.store : Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _shop?.name ?? 'ร้านค้าของคุณ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sellerProfile?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('แดชบอร์ด'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (_shop != null) ...[
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('หน้าร้าน'),
              onTap: () {
                // Navigate to store front
                Navigator.pop(context);
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('จัดการสินค้า'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('คำสั่งซื้อ'),
            trailing: _orderCount > 0
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _orderCount > 9 ? '9+' : _orderCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SellerOrdersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('รายงานและสถิติ'),
            onTap: () {
              // Navigate to reports
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('บัญชีผู้ใช้'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SellerAccountScreen(),
                ),
              );
            },
          ),
          if (_shop != null)
            ListTile(
              leading: const Icon(Icons.store_mall_directory),
              title: const Text('ตั้งร้านค้า'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShopManagementScreen(),
                  ),
                ).then((_) => _loadSellerData());
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_center),
            title: const Text('ช่วยเหลือและสนับสนุน'),
            onTap: () {
              // Navigate to help center
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/seller/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
