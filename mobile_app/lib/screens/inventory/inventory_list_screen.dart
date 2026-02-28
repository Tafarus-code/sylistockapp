import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../services/enhanced_inventory_service.dart';
import '../../models/enhanced_inventory_item.dart';
import 'item_details_screen.dart';
import 'item_form_screen.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _sortBy = 'name';
  bool _ascending = true;
  bool _isLoading = false;
  List<EnhancedInventoryItem> _items = [];
  List<InventoryCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final inventoryService = ref.read(enhancedInventoryServiceProvider);
      final items = await inventoryService.getAllItems();
      final categories = await inventoryService.getAllCategories();
      
      setState(() {
        _items = items;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  List<EnhancedInventoryItem> get _filteredItems {
    var filtered = _items.where((item) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(query) &&
            !(item.description?.toLowerCase().contains(query) ?? false) &&
            !(item.barcode?.contains(query) ?? false) &&
            !(item.supplier?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      if (_selectedCategoryId != null && item.categoryId != _selectedCategoryId) {
        return false;
      }
      
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'unitPrice':
          comparison = a.unitPrice.compareTo(b.unitPrice);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _ascending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsRow(),
                Expanded(child: _buildItemList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalItems = _filteredItems.length;
    final totalValue = _filteredItems.fold<double>(0, (sum, item) => sum + item.totalValue);
    final lowStockItems = _filteredItems.where((item) => item.isLowStock).length;
    final expiredItems = _filteredItems.where((item) => item.isExpired).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Items', '$totalItems', Icons.inventory),
          _buildStatItem('Value', '₵${totalValue.toStringAsFixed(0)}', Icons.attach_money),
          _buildStatItem('Low Stock', '$lowStockItems', Icons.warning, AppTheme.warningColor),
          _buildStatItem('Expired', '$expiredItems', Icons.error, AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.subtitle2.copyWith(
            color: color ?? AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.caption.copyWith(color: AppTheme.onSurfaceColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildItemList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: AppTheme.onSurfaceColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: AppTheme.headline6.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: AppTheme.bodyText2.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(EnhancedInventoryItem item) {
    final category = _categories.firstWhere(
      (cat) => cat.id == item.categoryId,
      orElse: () => InventoryCategory(name: 'Unknown'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.color),
          child: Text(
            item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          item.name,
          style: AppTheme.subtitle1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name),
            if (item.barcode != null)
              Text(
                'Barcode: ${item.barcode}',
                style: AppTheme.caption.copyWith(fontFamily: 'monospace'),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₵${item.unitPrice.toStringAsFixed(2)}',
              style: AppTheme.subtitle2.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Qty: ${item.quantity}',
              style: AppTheme.caption,
            ),
            if (item.isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Low Stock',
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _viewItemDetails(item),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Items'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Enter search term',
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Items'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Category'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ..._categories.map((category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategoryId = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Items'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sort by'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'quantity', child: Text('Quantity')),
                  DropdownMenuItem(value: 'unitPrice', child: Text('Unit Price')),
                  DropdownMenuItem(value: 'createdAt', child: Text('Created Date')),
                ],
                onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Ascending'),
                value: _ascending,
                onChanged: (value) => setState(() => _ascending = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemFormScreen()),
    ).then((_) => _loadData());
  }

  void _viewItemDetails(EnhancedInventoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)),
    ).then((_) => _loadData());
  }
}
