import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/enhanced_inventory_item.dart';
import '../../services/enhanced_inventory_service.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
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
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsCard(),
                Expanded(child: _buildCategoryList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Categories', '${_categories.length}', Icons.category),
          _buildStatItem('Active', '${_categories.where((c) => c.isActive).length}', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.headline6.copyWith(color: AppTheme.primaryColor),
        ),
        Text(
          label,
          style: AppTheme.caption.copyWith(color: AppTheme.onSurfaceColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
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
              'Add your first category to organize inventory',
              style: AppTheme.bodyText2.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(InventoryCategory category) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: category.isActive,
              onChanged: (value) => _toggleCategoryStatus(category, value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete'),
                ),
              ],
              onSelected: (value) => _handleCategoryAction(category, value as String),
            ),
          ],
        ),
        onTap: () => _editCategory(category),
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

  void _addCategory() {
    _showCategoryDialog();
  }

  void _editCategory(InventoryCategory category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({InventoryCategory? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    String selectedIcon = category?.icon ?? 'category';
    int selectedColor = category?.color ?? AppTheme.primaryColor.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'Enter category name',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter category description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Icon'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'category',
                    'inventory',
                    'electronics',
                    'clothing',
                    'food',
                    'books',
                    'tools',
                    'sports',
                    'toys',
                  ].map((icon) => ChoiceChip(
                    label: Icon(_getIconData(icon)),
                    selected: selectedIcon == icon,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => selectedIcon = icon);
                      }
                    },
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppTheme.primaryColor.value,
                    AppTheme.successColor.value,
                    AppTheme.warningColor.value,
                    AppTheme.errorColor.value,
                    AppTheme.insuranceColor.value,
                    AppTheme.kycColor.value,
                    Colors.purple.value,
                    Colors.orange.value,
                    Colors.teal.value,
                  ].map((color) => ChoiceChip(
                    label: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    selected: selectedColor == color,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => selectedColor = color);
                      }
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveCategory(
                category,
                nameController.text,
                descriptionController.text.isEmpty ? null : descriptionController.text,
                selectedIcon,
                selectedColor,
              ),
              child: Text(category == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory(
    InventoryCategory? category,
    String name,
    String? description,
    String icon,
    int color,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category name')),
      );
      return;
    }

    try {
      final inventoryService = ref.read(enhancedInventoryServiceProvider);
      
      final newCategory = InventoryCategory(
        id: category?.id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        isActive: category?.isActive ?? true,
      );

      if (category == null) {
        await inventoryService.createCategory(newCategory);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
      } else {
        await inventoryService.updateCategory(newCategory);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
      }

      Navigator.of(context).pop();
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleCategoryStatus(InventoryCategory category, bool isActive) async {
    try {
      final inventoryService = ref.read(enhancedInventoryServiceProvider);
      final updatedCategory = category.copyWith(isActive: isActive);
      await inventoryService.updateCategory(updatedCategory);
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleCategoryAction(InventoryCategory category, String action) {
    switch (action) {
      case 'edit':
        _editCategory(category);
        break;
      case 'delete':
        _deleteCategory(category);
        break;
    }
  }

  void _deleteCategory(InventoryCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final inventoryService = ref.read(enhancedInventoryServiceProvider);
                await inventoryService.deleteCategory(category.id);
                Navigator.of(context).pop();
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
