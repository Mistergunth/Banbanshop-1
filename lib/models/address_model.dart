class UserAddress {
  final int? id;
  final int userId;
  final String recipientName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String province;
  final String district;
  final String subdistrict;
  final String postalCode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  UserAddress({
    this.id,
    required this.userId,
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.province,
    required this.district,
    required this.subdistrict,
    required this.postalCode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Convert UserAddress to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'province': province,
      'district': district,
      'subdistrict': subdistrict,
      'postalCode': postalCode,
      'isDefault': isDefault ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a UserAddress from a Map
  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id'],
      userId: map['userId'],
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      province: map['province'] ?? '',
      district: map['district'] ?? '',
      subdistrict: map['subdistrict'] ?? '',
      postalCode: map['postalCode'] ?? '',
      isDefault: map['isDefault'] == 1,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      notes: map['notes'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  // Create a copy of the address with updated fields
  UserAddress copyWith({
    int? id,
    int? userId,
    String? recipientName,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? province,
    String? district,
    String? subdistrict,
    String? postalCode,
    bool? isDefault,
    double? latitude,
    double? longitude,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      province: province ?? this.province,
      district: district ?? this.district,
      subdistrict: subdistrict ?? this.subdistrict,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Format the full address
  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      'ตำบล/แขวง $subdistrict',
      'อำเภอ/เขต $district',
      'จังหวัด $province',
      'รหัสไปรษณีย์ $postalCode',
    ];
    
    // Remove any null or empty parts
    return parts.where((part) => part != null && part.isNotEmpty).join('\n');
  }
}
