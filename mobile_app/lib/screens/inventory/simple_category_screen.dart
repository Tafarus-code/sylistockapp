import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';

// Simple category model for testing
class SimpleCategory {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  SimpleCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SimpleCategory.fromJson(Map<String, dynamic> json) {
    return SimpleCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class SimpleCategoryScreen extends StatefulWidget {
  const SimpleCategoryScreen({Key? key}) : super(key: key);

  @override
  State<SimpleCategoryScreen> createState() => _SimpleCategoryScreenState();
}

class _SimpleCategoryScreenState extends State<SimpleCategoryScreen> {
  late Box<SimpleCategory> _categoryBox;
  List<SimpleCategory> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      // Open a simple box without adapters
      _categoryBox = await Hive.openBox('simple_categories');
      print('Simple category box opened successfully');
      
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
        title: const Text('Simple Category Test'),
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
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTestCategory() async {
    final category = SimpleCategory(
      id: const Uuid().v4(),
      name: 'Test Category ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Created at ${DateTime.now()}',
      createdAt: DateTime.now(),
    );

    try {
      await _categoryBox.put(category.id, category.toJson());
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
                final category = SimpleCategory(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  description: descriptionController.text.isEmpty 
                      ? null 
                      : descriptionController.text,
                  createdAt: DateTime.now(),
                );

                try {
                  await _categoryBox.put(category.id, category.toJson());
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
