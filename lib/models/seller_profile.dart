// seller_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerProfile {
  final String id; // This is assumed to be Firebase User UID (String)
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? shopName;
  final String? address;
  final String? province;
  final String? district;
  final String? subDistrict;
  final String? postalCode;
  final String? taxId;
  final String? idCardImageUrl;
  final String? logoUrl;
  final String? bannerUrl;
  final String? profileImageUrl;
  final String? status; // pending, approved, rejected
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.shopName,
    this.address,
    this.province,
    this.district,
    this.subDistrict,
    this.postalCode,
    this.taxId,
    this.idCardImageUrl,
    this.logoUrl,
    this.bannerUrl,
    this.profileImageUrl,
    this.status = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create a SellerProfile from a map (from Firestore)
  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      shopName: json['shopName'] as String?,
      address: json['address'] as String?,
      province: json['province'] as String?,
      district: json['district'] as String?,
      subDistrict: json['subDistrict'] as String?,
      postalCode: json['postalCode'] as String?,
      taxId: json['taxId'] as String?,
      idCardImageUrl: json['idCardImageUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      status: json['status'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert a SellerProfile to a map (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'shopName': shopName,
      'address': address,
      'province': province,
      'district': district,
      'subDistrict': subDistrict,
      'postalCode': postalCode,
      'taxId': taxId,
      'idCardImageUrl': idCardImageUrl,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'profileImageUrl': profileImageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt!),
      'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // Check if seller profile is complete
  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        email.isNotEmpty &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        shopName != null &&
        shopName!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        province != null &&
        province!.isNotEmpty &&
        district != null &&
        district!.isNotEmpty &&
        subDistrict != null &&
        subDistrict!.isNotEmpty &&
        postalCode != null &&
        postalCode!.isNotEmpty &&
        taxId != null &&
        taxId!.isNotEmpty &&
        idCardImageUrl != null &&
        idCardImageUrl!.isNotEmpty;
  }

  // Check if the seller is approved
  bool get isApproved => status == 'approved';

  // Check if the seller has a shop
  bool get hasShop => shopName != null && shopName!.isNotEmpty;

  // Create a copy of the SellerProfile with updated fields
  SellerProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? shopName,
    String? address,
    String? province,
    String? district,
    String? subDistrict,
    String? postalCode,
    String? taxId,
    String? logoUrl,
    String? bannerUrl,
    String? profileImageUrl,
    String? status,
  }) {
    return SellerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
      subDistrict: subDistrict ?? this.subDistrict,
      postalCode: postalCode ?? this.postalCode,
      taxId: taxId ?? this.taxId,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
      createdAt: createdAt, // Keep original createdAt
      updatedAt: updatedAt, // Keep original updatedAt
    );
  }
}
