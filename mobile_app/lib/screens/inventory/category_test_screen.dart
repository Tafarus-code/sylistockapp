import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/enhanced_inventory_service.dart';
import '../../models/enhanced_inventory_item.dart';

class CategoryTestScreen extends ConsumerWidget {
  const CategoryTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test direct Hive access first
                  final categoryBox = await Hive.openBox<InventoryCategory>('test_categories');
                  print('Direct Hive box opened successfully');
                  
                  final category = InventoryCategory(
                    name: 'Test Category ${DateTime.now().millisecondsSinceEpoch}',
                    description: 'A test category',
                    icon: 'category',
                    color: AppTheme.primaryColor.value,
                  );
                  
                  print('Category created: $category');
                  
                  // Save directly to Hive
                  await categoryBox.put(category.id, category);
                  print('Category saved directly to Hive');
                  
                  final savedCategory = categoryBox.get(category.id);
                  print('Retrieved category: $savedCategory');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category created successfully!')),
                  );
                } catch (e) {
                  print('Direct Hive Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Direct Hive Error: $e')),
                  );
                }
              },
              child: const Text('Test Direct Hive'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final inventoryService = ref.read(enhancedInventoryServiceProvider);
                  print('Service retrieved: $inventoryService');
                  
                  final category = InventoryCategory(
                    name: 'Test Category ${DateTime.now().millisecondsSinceEpoch}',
                    description: 'A test category',
                    icon: 'category',
                    color: AppTheme.primaryColor.value,
                  );
                  
                  print('Category created: $category');
                  
                  final result = await inventoryService.createCategory(category);
                  print('Category saved: $result');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category created successfully!')),
                  );
                } catch (e) {
                  print('Service Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Service Error: $e')),
                  );
                }
              },
              child: const Text('Test Service Create'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final inventoryService = ref.read(enhancedInventoryServiceProvider);
                  final categories = await inventoryService.getAllCategories();
                  
                  print('Categories retrieved: ${categories.length}');
                  for (final cat in categories) {
                    print('Category: ${cat.name} (${cat.id})');
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Found ${categories.length} categories')),
                  );
                } catch (e) {
                  print('Get Categories Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Get Categories Error: $e')),
                  );
                }
              },
              child: const Text('Test Service Get'),
            ),
          ],
        ),
      ),
    );
  }
}
