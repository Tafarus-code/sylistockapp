import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

@HiveType(typeId: 0)
class InventoryItem {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String barcode;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final String? description;
  @HiveField(5)
  final double? price;
  @HiveField(6)
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.quantity,
    this.description,
    this.price,
    required this.createdAt,
  });

  // Getter for compatibility
  String get productName => name;

  /// Parse JSON from Django backend.
  /// Django views return flat JSON:
  ///   { id, barcode, name, quantity, price, last_updated }
  /// Or nested from the old CBV:
  ///   { id, product: { barcode, name }, quantity, cost_price, ... }
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle nested product structure if present
    final product = json['product'] as Map<String, dynamic>?;

    return InventoryItem(
      id: json['id'] as int,
      barcode: product?['barcode'] as String? ??
          json['barcode'] as String? ??
          '',
      name: product?['name'] as String? ??
          json['name'] as String? ??
          '',
      quantity: json['quantity'] as int? ?? 0,
      description: json['description'] as String?,
      price: _parseDouble(json['price'] ?? json['sale_price']),
      createdAt: _parseDate(
          json['created_at'] ?? json['last_updated']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'quantity': quantity,
      'description': description,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
