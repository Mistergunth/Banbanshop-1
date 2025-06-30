import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:banbanshop/screens/seller/seller_dashboard_screen.dart';
import 'package:banbanshop/models/seller_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class NewSellerRegisterScreen extends StatefulWidget {
  const NewSellerRegisterScreen({Key? key}) : super(key: key);

  @override
  State<NewSellerRegisterScreen> createState() => _NewSellerRegisterScreenState();
}

class _NewSellerRegisterScreenState extends State<NewSellerRegisterScreen> {
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
    'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย', 'สุพรรณบุรี',
    'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู', 'อ่างทอง', 'อุดรธานี',
    'อุทัยธานี', 'อุตรดิตถ์', 'อุบลราชธานี', 'อำนาจเจริญ',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: ${e.toString()}')),
        );
      }
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
              ),
              const SizedBox(height: 12),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกอีเมล';
                  } else if (!value.contains('@') || !value.contains('.')) {
                    return 'กรุณากรอกอีเมลให้ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Phone Number
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'เช่น 0812345678',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  } else if (!_validatePhoneNumber(value)) {
                    return 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // ID Card Number
              TextFormField(
                controller: _idCardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'เลขบัตรประชาชน',
                  prefixIcon: Icon(Icons.credit_card),
                  hintText: '13 หลัก',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเลขบัตรประชาชน';
                  } else if (value.length != 13) {
                    return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                  } else if (!_validateThaiId(value)) {
                    return 'เลขบัตรประชาชนไม่ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // ID Card Image
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รูปภาพบัตรประชาชน', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickIdCardImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _idCardImage != null
                          ? Image.file(_idCardImage!, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.add_a_photo, size: 40)),
                    ),
                  ),
                  if (_idCardImage == null)
                    const Text(
                      'กรุณาอัปโหลดรูปภาพบัตรประชาชน',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'ที่อยู่',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกที่อยู่';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Province Dropdown
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                decoration: const InputDecoration(
                  labelText: 'จังหวัด',
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: _provinces.map((String province) {
                  return DropdownMenuItem<String>(
                    value: province,
                    child: Text(province),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'กรุณาเลือกจังหวัด';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // District and Sub-district
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'อำเภอ/เขต',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกอำเภอ/เขต';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _subDistrictController,
                      decoration: const InputDecoration(
                        labelText: 'ตำบล/แขวง',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกตำบล/แขวง';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Postal Code
              TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'รหัสไปรษณีย์',
                  prefixIcon: Icon(Icons.local_post_office),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสไปรษณีย์';
                  } else if (value.length != 5) {
                    return 'รหัสไปรษณีย์ต้องมี 5 หลัก';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสผ่าน';
                  } else if (value.length < 6) {
                    return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณายืนยันรหัสผ่าน';
                  } else if (value != _passwordController.text) {
                    return 'รหัสผ่านไม่ตรงกัน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _registerSeller,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('มีบัญชีผู้ขายอยู่แล้ว? '),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SellerLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
