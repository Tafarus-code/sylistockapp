// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_category_screen.dart';

// **************************************************************************
// HiveAdapter
// **************************************************************************

class SimpleCategoryAdapter extends TypeAdapter<SimpleCategory> {
  @override
  final int typeId = 2;

  @override
  SimpleCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) {
        final fieldId = reader.readByte();
        final value = reader.read();
        fields[fieldId] = value;
      }
    };

    return SimpleCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdAt: DateTime.parse(fields[3] as String),
    );
  }

  @override
  void write(BinaryWriter writer, SimpleCategory obj) {
    writer.writeByte(4);
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.createdAt.toIso8601String());
  }
}
