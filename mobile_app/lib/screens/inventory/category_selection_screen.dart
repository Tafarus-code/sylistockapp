import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../services/enhanced_inventory_service.dart';
import '../../models/enhanced_inventory_item.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends ConsumerState<CategorySelectionScreen> {
  bool _isLoading = false;
  List<InventoryCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final inventoryService = ref.read(enhancedInventoryServiceProvider);
      final categories = await inventoryService.getAllCategories();
      
      setState(() {
        _categories = categories.where((c) => c.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: AppTheme.onSurfaceColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No categories found',
                        style: AppTheme.headline6.copyWith(
                          color: AppTheme.onSurfaceColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add categories first to organize your inventory',
                        style: AppTheme.bodyText2.copyWith(
                          color: AppTheme.onSurfaceColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryTile(category);
                  },
                ),
    );
  }

  Widget _buildCategoryTile(InventoryCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.color),
          child: Icon(
            _getIconData(category.icon),
            color: Colors.white,
          ),
        ),
        title: Text(
          category.name,
          style: AppTheme.subtitle1,
        ),
        subtitle: category.description != null ? Text(category.description!) : null,
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.of(context).pop(category.id),
      ),
    );
  }

  IconData _getIconData(String? icon) {
    switch (icon) {
      case 'inventory':
        return Icons.inventory;
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'food':
        return Icons.restaurant;
      case 'books':
        return Icons.menu_book;
      case 'tools':
        return Icons.build;
      case 'sports':
        return Icons.sports_soccer;
      case 'toys':
        return Icons.toys;
      default:
        return Icons.category;
    }
  }
}
