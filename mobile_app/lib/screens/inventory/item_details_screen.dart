import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../services/enhanced_inventory_service.dart';
import '../../models/enhanced_inventory_item.dart';
import 'item_form_screen.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final EnhancedInventoryItem item;
  
  const ItemDetailsScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editItem(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteItem(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 16),
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildPricingCard(),
            const SizedBox(height: 16),
            _buildInventoryCard(),
            const SizedBox(height: 16),
            _buildDatesCard(),
            const SizedBox(height: 16),
            _buildTagsCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.dividerColor,
        ),
        child: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                ),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No Image', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', item.name),
            if (item.description != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Description', item.description!),
            ],
            if (item.barcode != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Barcode', item.barcode!, fontFamily: 'monospace'),
            ],
            if (item.qrCode != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('QR Code', item.qrCode!, fontFamily: 'monospace'),
            ],
            if (item.supplier != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Supplier', item.supplier!),
            ],
            if (item.location != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Location', item.location!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Unit Price', '₵${item.unitPrice.toStringAsFixed(2)}'),
            if (item.sellingPrice != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Selling Price', '₵${item.sellingPrice!.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildInfoRow('Profit Margin', '${item.profitMargin.toStringAsFixed(1)}%'),
            ],
            const SizedBox(height: 8),
            _buildInfoRow('Total Value', '₵${item.totalValue.toStringAsFixed(2)}'),
            if (item.sellingPrice != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Potential Revenue', '₵${item.potentialRevenue.toStringAsFixed(2)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Quantity', '${item.quantity}'),
            if (item.minStockLevel != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Min Stock Level', '${item.minStockLevel}'),
            ],
            if (item.maxStockLevel != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Max Stock Level', '${item.maxStockLevel}'),
            ],
            if (item.weight != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Weight', '${item.weight} kg'),
            ],
            if (item.dimensions != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Dimensions', item.dimensions!),
            ],
            const SizedBox(height: 16),
            _buildStatusIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (item.isLowStock)
          Chip(
            label: const Text('Low Stock'),
            backgroundColor: AppTheme.warningColor.withOpacity(0.1),
            labelStyle: TextStyle(color: AppTheme.warningColor),
          ),
        if (item.isOverStock)
          Chip(
            label: const Text('Over Stock'),
            backgroundColor: AppTheme.errorColor.withOpacity(0.1),
            labelStyle: TextStyle(color: AppTheme.errorColor),
          ),
        if (item.isExpiringSoon)
          Chip(
            label: const Text('Expiring Soon'),
            backgroundColor: AppTheme.warningColor.withOpacity(0.1),
            labelStyle: TextStyle(color: AppTheme.warningColor),
          ),
        if (item.isExpired)
          Chip(
            label: const Text('Expired'),
            backgroundColor: AppTheme.errorColor.withOpacity(0.1),
            labelStyle: TextStyle(color: AppTheme.errorColor),
          ),
        if (!item.isActive)
          Chip(
            label: const Text('Inactive'),
            backgroundColor: AppTheme.onSurfaceColor.withOpacity(0.1),
            labelStyle: TextStyle(color: AppTheme.onSurfaceColor),
          ),
      ],
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dates',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Created', '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
            _buildInfoRow('Updated', '${item.updatedAt.day}/${item.updatedAt.month}/${item.updatedAt.year}'),
            if (item.purchaseDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Purchase Date', '${item.purchaseDate!.day}/${item.purchaseDate!.month}/${item.purchaseDate!.year}'),
            ],
            if (item.expiryDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Expiry Date', '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    if (item.tags.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags.map((tag) => Chip(
                label: Text(tag),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    if (item.notes == null || item.notes!.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            Text(item.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? fontFamily}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTheme.subtitle2.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyText1.copyWith(
              fontFamily: fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  void _editItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemFormScreen(item: item)),
    );
  }

  void _deleteItem(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final inventoryService = ref.read(enhancedInventoryServiceProvider);
                await inventoryService.deleteItem(item.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted successfully')),
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
