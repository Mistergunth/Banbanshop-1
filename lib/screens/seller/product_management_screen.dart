import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/product_model.dart';
import 'product_edit_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load products when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/seller/products/edit',
              );
              
              if (result == true && mounted) {
                // Refresh the product list if a new product was added
                await context.read<AppProvider>().loadProducts();
              }
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          if (appProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = appProvider.products;
          
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('ยังไม่มีสินค้า'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มสินค้า'),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/seller/products/edit',
                      );
                      
                      if (result == true && mounted) {
                        // Refresh the product list if a new product was added
                        await context.read<AppProvider>().loadProducts();
                      }
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: product.imagePath != null
                      ? Image.network(
                          product.imagePath!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(product.name),
                  subtitle: Text('฿${product.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/seller/products/edit',
                            arguments: product,
                          );
                          
                          if (result == true && mounted) {
                            // Refresh the product list if the product was updated
                            await context.read<AppProvider>().loadProducts();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteDialog(context, product);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบสินค้า'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบสินค้า "${product.name}" นี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AppProvider>().removeProduct(
              int.parse(product.id!),
              imagePath: product.images.isNotEmpty ? product.images.first : null,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบสินค้าเรียบร้อยแล้ว')),
          );
          // Refresh the product list
          await context.read<AppProvider>().loadProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
          );
        }
      }
    }
  }
}
