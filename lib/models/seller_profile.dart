class SellerProfile {
  final String id;
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
    this.createdAt,
    this.updatedAt,
  });

  // Create a SellerProfile from a map (from database)
  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      shopName: json['shopName']?.toString(),
      address: json['address']?.toString(),
      province: json['province']?.toString(),
      district: json['district']?.toString(),
      subDistrict: json['subDistrict']?.toString(),
      postalCode: json['postalCode']?.toString(),
      taxId: json['taxId']?.toString(),
      idCardImageUrl: json['idCardImageUrl']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toDate(),
      updatedAt: json['updatedAt']?.toDate(),
    );
  }

  // Convert a SellerProfile to a map (for database)
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy of the SellerProfile with some updated fields
  SellerProfile copyWithFull({
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
    String? idCardImageUrl,
    String? logoUrl,
    String? bannerUrl,
    String? profileImageUrl,
    String? status,
  }) {
    return SellerProfile(
      id: id,
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
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Check if the seller profile is complete for registration
  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        email.isNotEmpty &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
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
    );
  }
}
