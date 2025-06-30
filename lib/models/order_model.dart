import 'product_model.dart';

class Order {
  final int? id;
  final int userId;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final String orderDate;
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
      id: map['id'],
      userId: map['userId'],
      totalAmount: map['totalAmount'] is int 
          ? (map['totalAmount'] as int).toDouble() 
          : map['totalAmount'],
      status: map['status'],
      shippingAddress: map['shippingAddress'],
      orderDate: map['orderDate'],
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final Product? product;

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
      id: map['id'],
      orderId: map['orderId'],
      productId: map['productId'],
      quantity: map['quantity'],
      price: map['price'] is int 
          ? (map['price'] as int).toDouble() 
          : map['price'],
    );
  }
}
