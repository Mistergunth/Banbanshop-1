// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:banbanshop/screens/seller/seller_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:banbanshop/models/seller_profile.dart';

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _subDistrictController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Form state
  String? _selectedProvince;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  File? _idCardImage;
  String? _idCardImageUrl;
  final ImagePicker _picker = ImagePicker();

  final List<String> _provinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น',
    'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร',
    'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก',
    'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี',
    'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์',
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร',
    'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต',
    'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด',
    'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย',
    'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม',
    'สมุทรสาคร', 'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อุดรธานี',
    'อุทัยธานี',
    'อุตรดิตถ์',
    'อุบลราชธานี',
    'อำนาจเจริญ',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _idCardNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // Function to handle ID card image selection
  Future<void> _pickIdCardImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _idCardImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}')),
      );
    }
  }

  // Function to upload ID card image to Firebase Storage
  Future<String?> _uploadIdCardImage(String userId) async {
    if (_idCardImage == null) return null;
    
    try {
      final fileName = 'id_cards/$userId/${path.basename(_idCardImage!.path)}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(_idCardImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: ${e.toString()}')),
      );
      return null;
    }
  }

  // Function to validate Thai ID number
  bool _validateThaiId(String id) {
    if (id.length != 13) return false;
    
    try {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        sum += int.parse(id[i]) * (13 - i);
      }
      
      int checkDigit = (11 - (sum % 11)) % 10;
      return checkDigit == int.parse(id[12]);
    } catch (e) {
      return false;
    }
  }

  // Function to validate phone number
  bool _validatePhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^0[0-9]{8,9}$');
    return phoneRegex.hasMatch(phone);
  }

  // Main registration function
  void _registerSeller() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดรูปภาพบัตรประชาชน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Register with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // 2. Upload ID card image
      String? idCardImageUrl = await _uploadIdCardImage(userCredential.user!.uid);
      
      if (idCardImageUrl == null) {
        throw Exception('ไม่สามารถอัปโหลดรูปภาพบัตรประชาชนได้');
      }

      // 3. Create seller profile
      final sellerProfile = SellerProfile(
        id: userCredential.user!.uid,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        address: _addressController.text.trim(),
        province: _selectedProvince,
        district: _districtController.text.trim(),
        subDistrict: _subDistrictController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        taxId: _idCardNumberController.text.trim(),
        profileImageUrl: idCardImageUrl,
      );

      // 4. Save seller profile to Firestore
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(userCredential.user!.uid)
          .set(sellerProfile.toJson());

      // 5. Navigate to seller dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SellerDashboardScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาดในการลงทะเบียน';
      if (e.code == 'weak-password') {
        message = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      } else if (e.code == 'email-already-in-use') {
        message = 'อีเมลนี้มีการใช้งานแล้ว';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิกผู้ขาย'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ-นามสกุล',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อ-นามสกุล';
                  }
                  return null;
                },
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เบอร์โทรศัพท์',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IntrinsicWidth(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: '+66',
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: <String>['+66'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(value),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    // This can be expanded to allow other country codes
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                onSaved: (String? phoneNumber) {
                  profile.phoneNumber = phoneNumber ?? '';
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  if (value.length != 10) {
                    return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'กรุณากรอกเฉพาะตัวเลข';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // สร้าง Dropdown สำหรับเลือกจังหวัด
  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'จังหวัดที่ตั้งร้าน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('เลือกจังหวัด'),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: _provinces.map((String province) {
            return DropdownMenuItem<String>(
              value: province,
              child: Text(province),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedProvince = newValue;
            });
          },
          onSaved: (String? value) {
            profile.province = value ?? ''; // บันทึกจังหวัดลงใน profile
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกจังหวัด';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }
}
