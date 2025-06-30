// lib/screens/post_model.dart

class Post {
  final String id;
  final String shopName;
  final DateTime createdAt;
  final String category;
  final String title;
  final String imageUrl;
  final String avatarImageUrl; 
  final String province;
  final String productCategory;
  final String ownerUid; 

  Post({
    required this.id,
    required this.shopName,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.avatarImageUrl, 
    required this.province,
    required this.productCategory,
    required this.ownerUid, 
  });

  // Factory constructor for creating Post from Map (from SQLite)
  factory Post.fromJson(Map<String, dynamic> json) {
    // Parse ISO 8601 string to DateTime
    DateTime createdAt = DateTime.parse(json['createdAt'] as String);
    return Post(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      createdAt: createdAt,
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      avatarImageUrl: json['avatarImageUrl']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      productCategory: json['productCategory']?.toString() ?? '',
      ownerUid: json['ownerUid']?.toString() ?? '', 
    );
  }

  // Convert Post to Map (for SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopName': shopName,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'title': title,
      'imageUrl': imageUrl,
      'avatarImageUrl': avatarImageUrl,
      'province': province,
      'productCategory': productCategory,
      'ownerUid': ownerUid,
    };
  }
}
