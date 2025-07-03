// shop_model.dart
import 'package:Maps_flutter/Maps_flutter.dart'; // แก้ไขจาก Maps_flutter
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // เพิ่มการ import สำหรับ debugPrint

class Shop {
  final int? id; // Changed from String to int?
  final int sellerId; // Changed from String to int
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
    this.id, // Changed from required this.id to this.id
    required this.sellerId, // Changed from String to int
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
      id: map['id'] as int?, // Changed to int?
      sellerId: map['sellerId'] as int, // Changed to int
      name: map['name'] as String,
      description: map['description'] as String,
      address: map['address'] as String,
      province: map['province'] as String,
      district: map['district'] as String?,
      subdistrict: map['subdistrict'] as String?,
      postalCode: map['postalCode'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      logo: map['logo'] as String?,
      coverImage: map['coverImage'] as String?,
      openTime: map['openTime'] as String?,
      closeTime: map['closeTime'] as String?,
      isOpen: (map['isOpen'] as int) == 1,
      isVerified: (map['isVerified'] as int) == 1,
      rating: map['rating'] as double,
      totalRatings: map['totalRatings'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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
      
      // Parse open and close times
      final openHour = int.parse(openTime!.split(':')[0]);
      final openMinute = int.parse(openTime!.split(':')[1]);
      final closeHour = int.parse(closeTime!.split(':')[0]);
      final closeMinute = int.parse(closeTime!.split(':')[1]);

      final openDateTime = DateTime(now.year, now.month, now.day, openHour, openMinute);
      final closeDateTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      // Handle overnight closing (e.g., 22:00 - 06:00)
      if (openDateTime.isBefore(closeDateTime)) {
        return now.isAfter(openDateTime) && now.isBefore(closeDateTime);
      } else {
        // Shop closes on the next day
        return now.isAfter(openDateTime) || now.isBefore(closeDateTime);
      }
    } catch (e) {
      debugPrint('Error checking shop open status: $e');
      return false;
    }
  }
}