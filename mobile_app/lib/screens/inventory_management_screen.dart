import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../models/inventory_item.dart';
import '../services/enhanced_scanner_service.dart';
import 'item_details_screen.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            onPressed: _showImportDialog,
            tooltip: 'Import Inventory',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportInventory,
            tooltip: 'Export Inventory',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildInventoryList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_circle,
                    label: 'Add Item',
                    color: Colors.green,
                    onTap: _showAddItemDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.upload_file,
                    label: 'Import CSV',
                    color: Colors.blue,
                    onTap: _showImportDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.download,
                    label: 'Export CSV',
                    color: Colors.orange,
                    onTap: _exportInventory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.trending_up,
                    label: 'Bulk Update',
                    color: Colors.purple,
                    onTap: _showBulkUpdateDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.analytics,
                    label: 'Reports',
                    color: Colors.red,
                    onTap: _showReportsDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is InventoryLoaded) {
          final items = _searchController.text.isEmpty
              ? state.items
              : state.items.where((item) =>
                  item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  item.barcode.toLowerCase().contains(_searchController.text.toLowerCase())
                ).toList();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchController.text.isEmpty ? Icons.inventory : Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty ? 'No inventory items' : 'No items found',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Barcode: ${item.barcode}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.price != null)
                              Text(
                                '\$${item.price!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editItem(item),
                              tooltip: 'Edit Item',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteItem(item),
                              tooltip: 'Delete Item',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailsScreen(item: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else if (state is InventoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _refreshInventory(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Press refresh to load inventory'));
      },
    );
  }

  void _showAddItemDialog() {
    // Implement add item dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add item feature - use Enhanced Scanner'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Inventory'),
        content: const Text('Import inventory from CSV file'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickAndImportFile();
            },
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showBulkUpdateDialog() {
    // Implement bulk update dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulk update feature - use Enhanced Scanner'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Sales Report'),
              onTap: () {
                Navigator.pop(context);
                _viewSalesReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Inventory Value'),
              onTap: () {
                Navigator.pop(context);
                _viewInventoryValueReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance Metrics'),
              onTap: () {
                Navigator.pop(context);
                _viewPerformanceReport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'Import CSV File',
      );

      if (result != null) {
        final file = result.files.first;
        // Here you would upload the file to your backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportInventory() async {
    try {
      // Here you would call your export API
      final backendUrl = await EnhancedScannerService.getBackendUrl();
      
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export feature - connect to backend at $backendUrl'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editItem(InventoryItem item) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit feature - use Enhanced Scanner'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would call the delete API
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete feature - use Enhanced Scanner'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewSalesReport() {
    // Navigate to sales report screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sales report - connect to backend'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewInventoryValueReport() {
    // Navigate to inventory value report screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inventory value report - connect to backend'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewPerformanceReport() {
    // Navigate to performance report screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance report - connect to backend'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _refreshInventory() {
    context.read<InventoryBloc>().add(LoadInventoryEvent());
  }
}
