import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  TestCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
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
    );
  }

  @override
  void write(BinaryWriter writer, TestCategory obj) {
    writer.writeByte(4);
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.createdAt.toIso8601String());
  }
}

class TestHiveScreen extends StatefulWidget {
  const TestHiveScreen({Key? key}) : super(key: key);

  @override
  State<TestHiveScreen> createState() => _TestHiveScreenState();
}

class _TestHiveScreenState extends State<TestHiveScreen> {
  late Box<TestCategory> _categoryBox;
  List<TestCategory> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      print('Starting Hive initialization...');
      
      // Register adapter
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TestCategoryAdapter());
        print('TestCategoryAdapter registered');
      }
      
      // Open box
      _categoryBox = await Hive.openBox<TestCategory>('test_categories');
      print('Test category box opened successfully');
      
      // Load existing categories
      await _loadCategories();
      
      setState(() {});
    } catch (e) {
      print('Error initializing Hive: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hive initialization error: $e')),
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      final keys = _categoryBox.keys;
      _categories.clear();
      
      for (final key in keys) {
        final category = _categoryBox.get(key);
        if (category != null) {
          _categories.add(category);
        }
      }
      
      print('Loaded ${_categories.length} categories');
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Hive'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addTestCategory,
                          child: const Text('Add Test Category'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loadCategories,
                          child: const Text('Refresh Categories'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _categories.isEmpty
                      ? const Center(
                          child: Text('No categories yet. Add one!'),
                        )
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(category.name),
                                subtitle: category.description != null 
                                    ? Text(category.description!)
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteCategory(category.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTestCategory() async {
    final category = TestCategory(
      id: const Uuid().v4(),
      name: 'Test Category ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Created at ${DateTime.now()}',
      createdAt: DateTime.now(),
    );

    try {
      await _categoryBox.put(category.id, category);
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully!')),
      );
    } catch (e) {
      print('Error adding category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _categoryBox.delete(id);
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final category = TestCategory(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  description: descriptionController.text.isEmpty 
                      ? null 
                      : descriptionController.text,
                  createdAt: DateTime.now(),
                );

                try {
                  await _categoryBox.put(category.id, category);
                  await _loadCategories();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category added successfully!')),
                  );
                } catch (e) {
                  print('Error adding category: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding category: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
