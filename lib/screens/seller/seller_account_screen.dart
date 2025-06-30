// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:banbanshop/database/database_helper.dart';
import 'package:banbanshop/models/user_model.dart';
import 'package:banbanshop/models/seller_profile.dart';

class SellerAccountScreen extends StatefulWidget { 
  final SellerProfile? sellerProfile; 
  const SellerAccountScreen({super.key, this.sellerProfile}); 

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  SellerProfile? _currentSellerProfile;
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user from SQLite database
      final user = await _databaseHelper.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentSellerProfile = SellerProfile(
            id: user.id.toString(),
            fullName: user.name,
            email: user.email,
            phoneNumber: user.phone ?? '',
            shopName: user.shopName ?? '',
            address: user.address ?? '',
            province: user.province ?? '',
            district: user.district ?? '',
            subDistrict: user.subDistrict ?? '',
            postalCode: user.postalCode ?? '',
            taxId: user.taxId ?? '',
            logoUrl: user.avatarUrl ?? '',
            bannerUrl: user.bannerUrl ?? '',
          );
        });
      } else {
        setState(() {
          _currentSellerProfile = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading seller profile: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ขาย')),
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

  // Function to pick and upload profile image
  Future<void> _pickAndUploadImage() async {
    if (!mounted) return;
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      
      if (pickedFile == null) return; // User cancelled the picker

      setState(() {
        _isLoading = true;
      });

      // Get the current user
      final user = await _databaseHelper.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนอัปโหลดรูปภาพ')),
          );
        }
        return;
      }

      // In a real app, you would upload the image to a server here
      // For now, we'll just use the local file path
      final imagePath = pickedFile.path;
      
      // Create an updated user with the new avatar URL
      final updatedUser = user.copyWith(
        avatarUrl: imagePath,
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      // Update the user in the local database
      final success = await _databaseHelper.updateUser(updatedUser);

      if (!mounted) return;
      
      if (success) {
        // Update the UI with the new profile image
        setState(() {
          _currentSellerProfile = _currentSellerProfile?.copyWith(
            logoUrl: imagePath,
          ) ?? SellerProfile(
            id: user.id.toString(),
            fullName: user.name,
            email: user.email,
            phoneNumber: user.phone ?? '',
            shopName: user.shopName ?? '',
            logoUrl: imagePath,
          );
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถอัปเดตโปรไฟล์ได้')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกหรืออัปโหลดรูปภาพ'),
          ),
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

  Future<void> _logoutSeller() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Clear the current user session
      final success = await _databaseHelper.logout();
      
      if (!mounted) return;
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากระบบแล้ว')),
        );
        
        // Navigate to login screen and remove all previous routes
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SellerLoginScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถออกจากระบบได้')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากระบบ')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // กำหนดรูปโปรไฟล์
    ImageProvider<Object> profileImage;
    final profileImagePath = _currentSellerProfile?.logoUrl;
    
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      if (profileImagePath.startsWith('http')) {
        profileImage = NetworkImage(profileImagePath);
      } else {
        // Handle local file path
        profileImage = FileImage(File(profileImagePath));
      }
    } else {
      // Use default asset image if no profile image is set
      profileImage = const AssetImage('assets/images/default_profile.png');
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0F7), 
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                GestureDetector( 
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage,
                    // Show camera icon when no profile image is set
                    child: profileImagePath == null || profileImagePath.isEmpty
                        ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentSellerProfile?.fullName ?? 'ชื่อ - นามสกุล',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_currentSellerProfile?.phoneNumber?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _currentSellerProfile!.phoneNumber!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                if (_currentSellerProfile?.email?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _currentSellerProfile!.email!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildActionButton(
                  text: 'สร้างร้านค้า', 
                  color: const Color(0xFFE2CCFB), 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้าสร้างร้านค้า')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'เปิด/ปิดร้าน', 
                  color: const Color(0xFFD6F6E0), 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เปิด/ปิดร้านค้า')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'ดูออเดอร์', 
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เปลี่ยนไปหน้าดูออเดอร์')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'จัดการสินค้า', 
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('จัดการสินค้า')),
                    );
                  },
                ),
                const SizedBox(height: 30),
                _buildLogoutButton(context), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) { 
    return GestureDetector(
      onTap: () {
        // Show confirmation dialog before logging out
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ออกจากระบบ'),
              content: const Text('คุณแน่ใจหรือไม่ที่ต้องการออกจากระบบ?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    _logoutSeller();
                  },
                  child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row( 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
// Extension for SellerProfile copyWith is now in seller_profile.dart
