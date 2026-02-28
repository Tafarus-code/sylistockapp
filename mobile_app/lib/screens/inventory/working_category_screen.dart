import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';

@HiveType(typeId: 4)
class WorkingCategory {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime createdAt;

  WorkingCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
}

class WorkingCategoryAdapter extends TypeAdapter<WorkingCategory> {
  @override
  final int typeId = 4;

  @override
  WorkingCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      final value = reader.read();
      fields[fieldId] = value;
    }

    return WorkingCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdAt: DateTime.parse(fields[3] as String),
    );
  }

  @override
  void write(BinaryWriter writer, WorkingCategory obj) {
    writer.writeByte(4);
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.createdAt.toIso8601String());
  }
}

class WorkingCategoryScreen extends ConsumerStatefulWidget {
  const WorkingCategoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkingCategoryScreen> createState() => _WorkingCategoryScreenState();
}

class _WorkingCategoryScreenState extends ConsumerState<WorkingCategoryScreen> {
  late Box<WorkingCategory> _categoryBox;
  List<WorkingCategory> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      // Register adapter
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(WorkingCategoryAdapter());
        print('WorkingCategoryAdapter registered');
      }
      
      // Open box
      _categoryBox = await Hive.openBox<WorkingCategory>('working_categories');
      print('Working category box opened successfully');
      
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
        title: const Text('Working Categories'),
        backgroundColor: AppTheme.primaryColor,
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
                          onPressed: _addCategory,
                          child: const Text('Add Working Category'),
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
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addCategory() async {
    final category = WorkingCategory(
      id: const Uuid().v4(),
      name: 'Working Category ${DateTime.now().millisecondsSinceEpoch}',
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
                final category = WorkingCategory(
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
