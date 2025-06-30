import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/location_model.dart';
import '../../../providers/buyer_provider.dart';
import '../../../widgets/app_bar.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final List<Province> _provinces = [
    Province(id: 1, name: 'กรุงเทพมหานคร'),
    Province(id: 2, name: 'นนทบุรี'),
    Province(id: 3, name: 'ปทุมธานี'),
    Province(id: 4, name: 'สมุทรปราการ'),
    Province(id: 5, name: 'สมุทรสาคร'),
  ];
  
  List<District> _districts = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Load districts for the first province by default
    _loadDistricts(_provinces.first.id);
  }
  
  void _loadDistricts(int provinceId) {
    setState(() {
      _isLoading = true;
      // Simulate API call
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _districts = _getSampleDistricts(provinceId);
          _isLoading = false;
        });
      });
    });
  }
  
  List<District> _getSampleDistricts(int provinceId) {
    // This is just sample data. In a real app, you would fetch this from an API
    final districts = {
      1: [
        District(id: 101, name: 'พระนคร', provinceId: 1),
        District(id: 102, name: 'ดุสิต', provinceId: 1),
        District(id: 103, name: 'หนองจอก', provinceId: 1),
        District(id: 104, name: 'บางรัก', provinceId: 1),
        District(id: 105, name: 'บางเขน', provinceId: 1),
      ],
      2: [
        District(id: 201, name: 'เมืองนนทบุรี', provinceId: 2),
        District(id: 202, name: 'บางบัวทอง', provinceId: 2),
        District(id: 203, name: 'ปากเกร็ด', provinceId: 2),
        District(id: 204, name: 'บางกรวย', provinceId: 2),
        District(id: 205, name: 'บางใหญ่', provinceId: 2),
      ],
      // Add more districts for other provinces as needed
    };
    
    return districts[provinceId] ?? [];
  }
  
  void _handleContinue() {
    final buyerProvider = Provider.of<BuyerProvider>(context, listen: false);
    if (buyerProvider.selectedProvince != null) {
      // Navigate to the home screen
      Navigator.pushReplacementNamed(context, '/buyer/home');
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกจังหวัด')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerProvider>(
      builder: (context, buyerProvider, child) {
        return Scaffold(
          appBar: const CustomAppBar(title: 'เลือกสถานที่'),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Province selection
                DropdownButtonFormField<Province>(
                  decoration: const InputDecoration(
                    labelText: 'จังหวัด',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  value: buyerProvider.selectedProvince,
                  items: _provinces.map((province) {
                    return DropdownMenuItem<Province>(
                      value: province,
                      child: Text(province.name),
                    );
                  }).toList(),
                  onChanged: (province) {
                    if (province != null) {
                      buyerProvider.setSelectedProvince(province);
                      _loadDistricts(province.id);
                    }
                  },
                  hint: const Text('เลือกจังหวัด'),
                  isExpanded: true,
                ),
                
                const SizedBox(height: 16),
                
                // District selection
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<District>(
                        decoration: const InputDecoration(
                          labelText: 'อำเภอ/เขต',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: buyerProvider.selectedDistrict,
                        items: _districts.map((district) {
                          return DropdownMenuItem<District>(
                            value: district,
                            child: Text(district.name),
                          );
                        }).toList(),
                        onChanged: (district) {
                          if (district != null) {
                            buyerProvider.setSelectedDistrict(district);
                          }
                        },
                        hint: const Text('เลือกอำเภอ/เขต'),
                        isExpanded: true,
                        validator: (value) {
                          if (value == null) {
                            return 'กรุณาเลือกอำเภอ/เขต';
                          }
                          return null;
                        },
                      ),
                
                const Spacer(),
                
                // Continue button
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ต่อไป',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
