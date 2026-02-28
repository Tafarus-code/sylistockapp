// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_inventory_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnhancedInventoryItemAdapter extends TypeAdapter<EnhancedInventoryItem> {
  @override
  final int typeId = 0;

  @override
  EnhancedInventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnhancedInventoryItem(
      id: fields[0] as String?,
      name: fields[1] as String,
      barcode: fields[2] as String?,
      qrCode: fields[3] as String?,
      description: fields[4] as String?,
      categoryId: fields[5] as String,
      quantity: fields[6] as int,
      unitPrice: fields[7] as double,
      sellingPrice: fields[8] as double?,
      supplier: fields[9] as String?,
      purchaseDate: fields[10] as DateTime?,
      expiryDate: fields[11] as DateTime?,
      location: fields[12] as String?,
      tags: (fields[13] as List).cast<String>(),
      isActive: fields[14] as bool,
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
      imageUrl: fields[17] as String?,
      weight: fields[18] as double?,
      dimensions: fields[19] as String?,
      minStockLevel: fields[20] as int?,
      maxStockLevel: fields[21] as int?,
      notes: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EnhancedInventoryItem obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.qrCode)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.unitPrice)
      ..writeByte(8)
      ..write(obj.sellingPrice)
      ..writeByte(9)
      ..write(obj.supplier)
      ..writeByte(10)
      ..write(obj.purchaseDate)
      ..writeByte(11)
      ..write(obj.expiryDate)
      ..writeByte(12)
      ..write(obj.location)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.imageUrl)
      ..writeByte(18)
      ..write(obj.weight)
      ..writeByte(19)
      ..write(obj.dimensions)
      ..writeByte(20)
      ..write(obj.minStockLevel)
      ..writeByte(21)
      ..write(obj.maxStockLevel)
      ..writeByte(22)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedInventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InventoryCategoryAdapter extends TypeAdapter<InventoryCategory> {
  @override
  final int typeId = 1;

  @override
  InventoryCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryCategory(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String?,
      icon: fields[3] as String?,
      color: fields[4] as int,
      parentId: fields[5] as String?,
      isActive: fields[6] as bool,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryCategory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.parentId)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
