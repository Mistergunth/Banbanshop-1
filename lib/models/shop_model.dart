import 'package:google_maps_flutter/google_maps_flutter.dart';

class Shop {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String address;
  final String province;
  final String? district;
  final String? subdistrict;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String? email;
  final String? logo;
  final String? coverImage;
  final String? openTime;
  final String? closeTime;
  final bool isOpen;
  final bool isVerified;
  final double rating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.address,
    required this.province,
    this.district,
    this.subdistrict,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.phone,
    this.email,
    this.logo,
    this.coverImage,
    this.openTime,
    this.closeTime,
    this.isOpen = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalRatings = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert a Shop into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'address': address,
      'province': province,
      'district': district,
      'subdistrict': subdistrict,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'logo': logo,
      'coverImage': coverImage,
      'openTime': openTime,
      'closeTime': closeTime,
      'isOpen': isOpen ? 1 : 0,
      'isVerified': isVerified ? 1 : 0,
      'rating': rating,
      'totalRatings': totalRatings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a Shop from a Map
  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'].toString(),
      sellerId: map['sellerId'].toString(),
      name: map['name'] ?? 'ร้านค้า',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      province: map['province'] ?? '',
      district: map['district'],
      subdistrict: map['subdistrict'],
      postalCode: map['postalCode'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      phone: map['phone'] ?? '',
      email: map['email'],
      logo: map['logo'],
      coverImage: map['coverImage'],
      openTime: map['openTime'],
      closeTime: map['closeTime'],
      isOpen: map['isOpen'] == 1 || map['isOpen'] == true,
      isVerified: map['isVerified'] == 1 || map['isVerified'] == true,
      rating: map['rating']?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // Get LatLng for Google Maps
  LatLng? get latLng {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude!, longitude!);
  }

  // Get full address
  String get fullAddress {
    final parts = [
      address,
      if (subdistrict?.isNotEmpty ?? false) 'ต.$subdistrict',
      if (district?.isNotEmpty ?? false) 'อ.$district',
      'จ.$province',
      if (postalCode?.isNotEmpty ?? false) postalCode,
    ].where((part) => part != null && part.isNotEmpty).toList();
    
    return parts.join(' ');
  }

  // Get operating hours
  String? get operatingHours {
    if (openTime == null || closeTime == null) return null;
    return '$openTime - $closeTime';
  }

  // Check if shop is currently open
  bool get isCurrentlyOpen {
    if (!isOpen || openTime == null || closeTime == null) return false;
    
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // Simple time comparison (for demo purposes)
      // In a real app, you'd want more robust time comparison
      return currentTime.compareTo(openTime!) >= 0 && 
             currentTime.compareTo(closeTime!) <= 0;
    } catch (e) {
      return false;
    }
  }
}
