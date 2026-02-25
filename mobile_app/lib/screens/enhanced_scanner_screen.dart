import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../models/inventory_item.dart';
import '../services/enhanced_scanner_service.dart';
import 'item_details_screen.dart';

class EnhancedScannerScreen extends StatefulWidget {
  const EnhancedScannerScreen({super.key});

  @override
  State<EnhancedScannerScreen> createState() => _EnhancedScannerScreenState();
}

class _EnhancedScannerScreenState extends State<EnhancedScannerScreen> {
  bool _isOnline = true;
  bool _showAdvancedOptions = false;
  int _pendingSyncCount = 0;
  DateTime? _lastSyncTime;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeEnhancedScanner();
  }

  Future<void> _initializeEnhancedScanner() async {
    await EnhancedScannerService.initialize();
    _checkConnectivity();
    _loadPendingSyncCount();
  }

  void _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _loadPendingSyncCount() async {
    final queue = await EnhancedScannerService.getQueue();
    final lastSync = await EnhancedScannerService.getLastSyncTime();
    setState(() {
      _pendingSyncCount = queue.length;
      _lastSyncTime = lastSync;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Sylistock Pro'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: Colors.white,
            ),
            onPressed: _showSyncDialog,
            tooltip: 'Sync Status',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Text('Scan History'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'low_stock',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text('Low Stock Alerts'),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 8),
          _buildQuickActions(),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                if (_showAdvancedOptions) ...[
                  Expanded(flex: 2, child: _buildManualEntry()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInventoryList()),
                ] else ...[
                  Expanded(child: _buildInventoryList()),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "manual_entry",
            onPressed: _showManualEntryDialog,
            icon: const Icon(Icons.keyboard),
            label: const Text('Add Item'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 8),
          if (_pendingSyncCount > 0)
            FloatingActionButton.extended(
              heroTag: "sync_queue",
              onPressed: _syncPendingItems,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Queue'),
              backgroundColor: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'Connected' : 'Offline Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_pendingSyncCount > 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      '$_pendingSyncCount items pending sync',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (_lastSyncTime != null)
              Text(
                'Last sync: ${_formatDateTime(_lastSyncTime!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                    icon: Icons.camera_alt,
                    label: 'Camera Scan',
                    color: Colors.blue,
                    onTap: () => _showCameraScanner(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.keyboard,
                    label: 'Manual Entry',
                    color: Colors.orange,
                    onTap: _showManualEntryDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sync,
                    label: 'Sync Now',
                    color: Colors.green,
                    onTap: _syncPendingItems,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.tune,
                    label: _showAdvancedOptions ? 'Simple View' : 'Advanced Options',
                    color: Colors.purple,
                    onTap: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
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

  Widget _buildManualEntry() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Add Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addInventoryItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Add Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
                child: RefreshIndicator(
                  onRefresh: () async => _refreshInventory(),
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteItem(item),
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
                  onPressed: _refreshInventory,
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

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'history':
        _showScanHistory();
        break;
      case 'low_stock':
        _showLowStockAlerts();
        break;
    }
  }

  void _showCameraScanner() {
    // Implement camera scanner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera scanner feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_barcodeController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _addInventoryItem();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addInventoryItem() async {
    final barcode = _barcodeController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text);

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a barcode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await EnhancedScannerService.addInventoryItem(
        barcode: barcode,
        name: 'Product $barcode', // Default name
        quantity: quantity,
        price: price,
      );

      if (result['success']) {
        _barcodeController.clear();
        _quantityController.clear();
        _priceController.clear();
        _refreshInventory();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editItem(InventoryItem item) {
    // Implement item editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit feature coming soon!'),
        backgroundColor: Colors.orange,
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
              // Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete feature coming soon!'),
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

  void _refreshInventory() {
    context.read<InventoryBloc>().add(LoadInventoryEvent());
  }

  void _syncPendingItems() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Syncing Queue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Syncing pending items...'),
          ],
        ),
      ),
    );

    try {
      final result = await EnhancedScannerService.syncQueue();
      Navigator.pop(context);

      if (result['success']) {
        _loadPendingSyncCount(); // Refresh count
        _refreshInventory();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result['synced_count']} items. ${result['failed_count']} failed.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_isOnline ? 'Online' : 'Offline'}'),
            const SizedBox(height: 8),
            if (_lastSyncTime != null)
              Text('Last sync: ${_formatDateTime(_lastSyncTime!)}'),
            if (_pendingSyncCount > 0)
              Text('Pending items: $_pendingSyncCount'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                if (_pendingSyncCount > 0)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _syncPendingItems();
                    },
                    child: const Text('Sync Now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScanHistory() {
    // Implement scan history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan history feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showLowStockAlerts() {
    // Implement low stock alerts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Low stock alerts feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
