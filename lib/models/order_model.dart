// order_model.dart
import 'product_model.dart'; // Ensure product_model.dart is imported

class Order {
  final int? id;
  final int userId;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final String orderDate; // Stored as ISO8601 String
  final List<OrderItem>? items;

  Order({
    this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.orderDate,
    this.items,
  });

  // Convert an Order into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress,
      'orderDate': orderDate,
    };
  }

  // Create an Order from a Map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      totalAmount: map['totalAmount'] is int
          ? (map['totalAmount'] as int).toDouble()
          : map['totalAmount'] as double,
      status: map['status'] as String,
      shippingAddress: map['shippingAddress'] as String,
      orderDate: map['orderDate'] as String,
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final Product? product; // Product details can be included when fetching order items

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  // Convert an OrderItem into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }

  // Create an OrderItem from a Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['orderId'] as int,
      productId: map['productId'] as int,
      quantity: map['quantity'] as int,
      price: map['price'] as double,
      // product field is typically populated through a join query in the repository
      product: null, // Will be populated separately if needed
    );
  }
}