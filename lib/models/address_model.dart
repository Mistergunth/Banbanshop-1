// user_model.dart
enum UserRole {
  customer,
  seller,
  admin
}

class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? address;
  final String? profileImage;
  final String? idCardImage; // For seller verification
  final UserRole role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.address,
    this.profileImage,
    this.idCardImage,
    this.role = UserRole.customer, // Default role is customer
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Convert a User into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'address': address,
      'profileImage': profileImage,
      'idCardImage': idCardImage,
      'role': role.toString().split('.').last, // Convert enum to string
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a User from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      password: map['password'] as String,
      address: map['address'] as String?,
      profileImage: map['profileImage'] as String?,
      idCardImage: map['idCardImage'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.customer,
      ),
      isActive: (map['isActive'] as int) == 1,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  // Create a copy of the user with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? address,
    String? profileImage,
    String? idCardImage,
    UserRole? role,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      idCardImage: idCardImage ?? this.idCardImage,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if user is a buyer
  bool get isBuyer => role == UserRole.customer;

  // Check if user is a seller
  bool get isSeller => role == UserRole.seller;

  // Check if user is an admin
  bool get isAdmin => role == UserRole.admin;
}