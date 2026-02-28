import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'enhanced_inventory_item.g.dart';

@HiveType(typeId: 0)
class EnhancedInventoryItem extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String? barcode;
  
  @HiveField(3)
  String? qrCode;
  
  @HiveField(4)
  String? description;
  
  @HiveField(5)
  String categoryId;
  
  @HiveField(6)
  int quantity;
  
  @HiveField(7)
  double unitPrice;
  
  @HiveField(8)
  double? sellingPrice;
  
  @HiveField(9)
  String? supplier;
  
  @HiveField(10)
  DateTime? purchaseDate;
  
  @HiveField(11)
  DateTime? expiryDate;
  
  @HiveField(12)
  String? location;
  
  @HiveField(13)
  List<String> tags;
  
  @HiveField(14)
  bool isActive;
  
  @HiveField(15)
  DateTime createdAt;
  
  @HiveField(16)
  DateTime updatedAt;
  
  @HiveField(17)
  String? imageUrl;
  
  @HiveField(18)
  double? weight;
  
  @HiveField(19)
  String? dimensions;
  
  @HiveField(20)
  int? minStockLevel;
  
  @HiveField(21)
  int? maxStockLevel;
  
  @HiveField(22)
  String? notes;

  EnhancedInventoryItem({
    String? id,
    required this.name,
    this.barcode,
    this.qrCode,
    this.description,
    required this.categoryId,
    this.quantity = 0,
    this.unitPrice = 0.0,
    this.sellingPrice,
    this.supplier,
    this.purchaseDate,
    this.expiryDate,
    this.location,
    this.tags = const [],
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.imageUrl,
    this.weight,
    this.dimensions,
    this.minStockLevel,
    this.maxStockLevel,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Computed properties
  double get totalValue => quantity * unitPrice;
  
  double get potentialRevenue => quantity * (sellingPrice ?? unitPrice);
  
  double get profitMargin {
    if (sellingPrice == null || unitPrice == 0) return 0.0;
    return ((sellingPrice! - unitPrice) / sellingPrice!) * 100;
  }
  
  bool get isLowStock {
    if (minStockLevel == null) return false;
    return quantity <= minStockLevel!;
  }
  
  bool get isOverStock {
    if (maxStockLevel == null) return false;
    return quantity >= maxStockLevel!;
  }
  
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }
  
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  // Methods
  EnhancedInventoryItem copyWith({
    String? name,
    String? barcode,
    String? qrCode,
    String? description,
    String? categoryId,
    int? quantity,
    double? unitPrice,
    double? sellingPrice,
    String? supplier,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? location,
    List<String>? tags,
    bool? isActive,
    DateTime? updatedAt,
    String? imageUrl,
    double? weight,
    String? dimensions,
    int? minStockLevel,
    int? maxStockLevel,
    String? notes,
  }) {
    return EnhancedInventoryItem(
      id: id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      supplier: supplier ?? this.supplier,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      imageUrl: imageUrl ?? this.imageUrl,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'qrCode': qrCode,
      'description': description,
      'categoryId': categoryId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'sellingPrice': sellingPrice,
      'supplier': supplier,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'location': location,
      'tags': tags,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'weight': weight,
      'dimensions': dimensions,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'notes': notes,
    };
  }

  factory EnhancedInventoryItem.fromJson(Map<String, dynamic> json) {
    return EnhancedInventoryItem(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      qrCode: json['qrCode'],
      description: json['description'],
      categoryId: json['categoryId'],
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      sellingPrice: json['sellingPrice']?.toDouble(),
      supplier: json['supplier'],
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      location: json['location'],
      tags: List<String>.from(json['tags'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      imageUrl: json['imageUrl'],
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'],
      minStockLevel: json['minStockLevel'],
      maxStockLevel: json['maxStockLevel'],
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'EnhancedInventoryItem(id: $id, name: $name, quantity: $quantity, category: $categoryId)';
  }
}

@HiveType(typeId: 1)
class InventoryCategory extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String? description;
  
  @HiveField(3)
  String? icon;
  
  @HiveField(4)
  int color;
  
  @HiveField(5)
  String? parentId;
  
  @HiveField(6)
  bool isActive;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  DateTime updatedAt;

  InventoryCategory({
    String? id,
    required this.name,
    this.description,
    this.icon,
    this.color = 0xFF1976D2,
    this.parentId,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  InventoryCategory copyWith({
    String? name,
    String? description,
    String? icon,
    int? color,
    String? parentId,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return InventoryCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'parentId': parentId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'] ?? 0xFF1976D2,
      parentId: json['parentId'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'InventoryCategory(id: $id, name: $name)';
  }
}
