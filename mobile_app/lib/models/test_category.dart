import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 3)
class TestCategory {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final bool isActive;

  TestCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });
}

class TestCategoryAdapter extends TypeAdapter<TestCategory> {
  @override
  final int typeId = 3;

  @override
  TestCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      final value = reader.read();
      fields[fieldId] = value;
    }

    return TestCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdAt: DateTime.parse(fields[3] as String),
      isActive: fields[4] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, TestCategory obj) {
    writer.writeByte(5);
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.createdAt.toIso8601String());
    writer.write(obj.isActive);
  }
}
