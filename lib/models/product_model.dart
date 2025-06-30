import 'dart:convert';

class Product {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final double? discount;
  final int stock;
  final String categoryId;
  final String? subCategoryId;
  final bool isAvailable;
  final bool isFeatured;
  final List<String> images;
  final List<String> tags;
  final int viewCount;
  final int soldCount;
  final double rating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sellerId; // Optional, for backward compatibility

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.stock,
    required this.categoryId,
    this.subCategoryId,
    this.isAvailable = true,
    this.isFeatured = false,
    List<String>? images,
    List<String>? tags,
    this.viewCount = 0,
    this.soldCount = 0,
    this.rating = 0.0,
    this.totalRatings = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sellerId, // For backward compatibility
  })  : images = images ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert a Product into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'stock': stock,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'isAvailable': isAvailable ? 1 : 0,
      'isFeatured': isFeatured ? 1 : 0,
      'images': jsonEncode(images),
      'tags': jsonEncode(tags),
      'viewCount': viewCount,
      'soldCount': soldCount,
      'rating': rating,
      'totalRatings': totalRatings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sellerId': sellerId, // For backward compatibility
    };
  }

  // Create a Product from a Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      shopId: map['shopId']?.toString() ?? '',
      name: map['name'] ?? 'สินค้า',
      description: map['description'] ?? '',
      price: map['price'] is int 
          ? (map['price'] as int).toDouble() 
          : (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: map['originalPrice']?.toDouble(),
      discount: map['discount']?.toDouble(),
      stock: map['stock'] is int 
          ? map['stock'] 
          : int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      categoryId: map['categoryId']?.toString() ?? '',
      subCategoryId: map['subCategoryId']?.toString(),
      isAvailable: map['isAvailable'] == 1 || map['isAvailable'] == true,
      isFeatured: map['isFeatured'] == 1 || map['isFeatured'] == true,
      images: map['images'] != null 
          ? List<String>.from(jsonDecode(map['images'])) 
          : [],
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'])) 
          : [],
      viewCount: map['viewCount'] ?? 0,
      soldCount: map['soldCount'] ?? 0,
      rating: map['rating']?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      sellerId: map['sellerId']?.toString(), // For backward compatibility
    );
  }

  // Get the first image URL or a placeholder
  String get imageUrl => images.isNotEmpty ? images.first : 'assets/images/placeholder.png';
  
  // For backward compatibility
  String get imagePath => imageUrl;

  // Get the final price after discount
  double get finalPrice {
    if (discount != null && discount! > 0) {
      return price * (1 - discount! / 100);
    }
    return price;
  }

  // Check if the product is on sale
  bool get isOnSale => discount != null && discount! > 0;

  // Get discount percentage as string
  String get discountPercentage => isOnSale ? '${discount!.toInt()}%' : '';

  // Get price with Thai Baht symbol
  String get formattedPrice => '฿${price.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '')}';
  
  // Get final price with Thai Baht symbol
  String get formattedFinalPrice => '฿${finalPrice.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '')}';

  // Get stock status
  String get stockStatus {
    if (stock <= 0) return 'สินค้าหมด';
    if (stock < 10) return 'เหลือ $stock ชิ้น';
    return 'มีสินค้า';
  }

  // Check if the product is out of stock
  bool get isOutOfStock => stock <= 0;

  // Create a copy of the product with updated fields
  Product copyWith({
    String? id,
    String? shopId,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    double? discount,
    int? stock,
    String? categoryId,
    String? subCategoryId,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? images,
    List<String>? tags,
    int? viewCount,
    int? soldCount,
    double? rating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discount: discount ?? this.discount,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      soldCount: soldCount ?? this.soldCount,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
