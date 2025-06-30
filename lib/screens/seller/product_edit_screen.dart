import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/product_model.dart';
import '../../../providers/app_provider.dart';

class ProductEditScreen extends StatefulWidget {
  final Product? product;

  const ProductEditScreen({super.key, this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  File? _imageFile;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      // Editing existing product
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.categoryId;
      _imagePath = widget.product!.images.isNotEmpty ? widget.product!.images.first : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagePath = null; // Clear the existing image path if any
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        // Get current user ID if available
        final currentUser = context.read<AppProvider>().currentUser;
        final sellerId = currentUser?.id?.toString();
        
        // Create or update product
        final product = Product(
          id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: widget.product?.shopId ?? 'default_shop_id', // TODO: Get from current user's shop
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          stock: int.parse(_stockController.text.trim()),
          categoryId: _categoryController.text.trim(),
          images: _imageFile != null 
              ? [_imageFile!.path] 
              : widget.product?.images ?? [],
          sellerId: sellerId,
          isAvailable: widget.product?.isAvailable ?? true,
          isFeatured: widget.product?.isFeatured ?? false,
        );

        if (widget.product == null) {
          // Add new product
          await context.read<AppProvider>().addProduct(
                product,
                imageFile: _imageFile,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เพิ่มสินค้าเรียบร้อยแล้ว')),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing product
          await context.read<AppProvider>().updateProduct(
                product,
                imageFile: _imageFile,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('อัปเดตสินค้าเรียบร้อยแล้ว')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'เพิ่มสินค้าใหม่' : 'แก้ไขสินค้า'),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ยืนยันการลบสินค้า'),
                    content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบสินค้านี้?'),
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
                          int.parse(widget.product!.id!),
                          imagePath: widget.product!.images.isNotEmpty ? widget.product!.images.first : null,
                        );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ลบสินค้าเรียบร้อยแล้ว')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : _imagePath != null
                                ? Image.network(
                                    _imagePath!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'เพิ่มรูปภาพสินค้า',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสินค้า',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกชื่อสินค้า';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดสินค้า',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรายละเอียดสินค้า';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Stock
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ราคา (บาท)',
                              border: OutlineInputBorder(),
                              prefixText: '฿ ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกราคา';
                              }
                              if (double.tryParse(value) == null) {
                                return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Stock
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'จำนวนในสต็อก',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกจำนวน';
                              }
                              if (int.tryParse(value) == null) {
                                return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกหมวดหมู่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.product == null ? 'เพิ่มสินค้า' : 'บันทึกการเปลี่ยนแปลง',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
