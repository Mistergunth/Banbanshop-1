import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final String? parentId;
  final String? icon;
  final Color? color;
  final bool isActive;

  ProductCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.icon,
    this.color,
    this.isActive = true,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'].toString(),
      name: map['name'],
      parentId: map['parentId']?.toString(),
      icon: map['icon'],
      color: map['color'] != null ? Color(int.parse(map['color'])) : null,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'icon': icon,
      'color': color?.value.toString(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Get all main categories (without parent)
  static List<ProductCategory> getMainCategories() {
    return [
      ProductCategory(
        id: 'food',
        name: 'อาหารและเครื่องดื่ม',
        icon: '🍜',
        color: Colors.orange.shade100,
      ),
      ProductCategory(
        id: 'handicraft',
        name: 'หัตถกรรม',
        icon: '🧶',
        color: Colors.blue.shade100,
      ),
      ProductCategory(
        id: 'clothing',
        name: 'เสื้อผ้าและแฟชั่น',
        icon: '👕',
        color: Colors.purple.shade100,
      ),
      ProductCategory(
        id: 'health',
        name: 'สุขภาพและความงาม',
        icon: '💆',
        color: Colors.pink.shade100,
      ),
      ProductCategory(
        id: 'home',
        name: 'ของใช้ในบ้าน',
        icon: '🏠',
        color: Colors.green.shade100,
      ),
      ProductCategory(
        id: 'other',
        name: 'อื่นๆ',
        icon: '📦',
        color: Colors.grey.shade200,
      ),
    ];
  }

  // Get subcategories based on parent category ID
  static List<ProductCategory> getSubcategories(String parentId) {
    final subcategories = {
      'food': [
        ProductCategory(
          id: 'food_snack',
          name: 'ขนมขบเคี้ยว',
          parentId: 'food',
          icon: '🍪',
        ),
        ProductCategory(
          id: 'food_dessert',
          name: 'ขนมไทย',
          parentId: 'food',
          icon: '🍡',
        ),
        ProductCategory(
          id: 'food_ingredient',
          name: 'วัตถุดิบอาหาร',
          parentId: 'food',
          icon: '🥬',
        ),
      ],
      'handicraft': [
        ProductCategory(
          id: 'handicraft_fabric',
          name: 'ผ้าทอพื้นเมือง',
          parentId: 'handicraft',
          icon: '🧵',
        ),
        ProductCategory(
          id: 'handicraft_wood',
          name: 'งานไม้',
          parentId: 'handicraft',
          icon: '🪵',
        ),
      ],
      // Add more subcategories as needed
    };

    return subcategories[parentId] ?? [];
  }
}
