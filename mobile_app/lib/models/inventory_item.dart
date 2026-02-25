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

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as int,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      description: json['description'] as String?,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
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

