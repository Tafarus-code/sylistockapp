import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../services/optimized_datawedge_service.dart';
import 'item_details_screen.dart';

class EnhancedScannerScreen extends ConsumerStatefulWidget {
  const EnhancedScannerScreen({super.key});

  @override
  ConsumerState<EnhancedScannerScreen> createState() => _EnhancedScannerScreenState();
}

class _EnhancedScannerScreenState extends ConsumerState<EnhancedScannerScreen> {
  bool _isOnline = true;
  bool _showAdvancedOptions = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeEnhancedScanner();
    // Initialize with local data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InventoryService.initializeWithLocalData(ref);
    });
  }

  Future<void> _initializeEnhancedScanner() async {
    await OptimizedDataWedgeService.instance.initialize();
    await OptimizedDataWedgeService.instance.optimizeFor4G();
    await OptimizedDataWedgeService.instance.enableBackgroundSync();
    await OptimizedDataWedgeService.instance.optimizeBatteryUsage();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krediti-GN Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Online/Offline status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Pending sync indicator
          if (pendingSyncCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sync,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingSyncCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions panel
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAdvancedOptions(),
                    icon: Icon(_showAdvancedOptions ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showAdvancedOptions ? 'Simple' : 'Advanced'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => InventoryService.refreshFromServer(ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          // Advanced options panel
          if (_showAdvancedOptions) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Manual Barcode Entry',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addManualItem(),
                      child: const Text('Add Item Manually'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Search bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Inventory list
          Expanded(
            child: Builder(
              builder: (context) {
                final items = InventoryService.currentItems;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items in inventory',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start scanning barcodes to add items',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.inventory,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text('Barcode: ${item.barcode}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) => _handleItemAction(item, value as String),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToItemDetails(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dashboard button
          FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.dashboard),
            heroTag: "dashboard",
          ),
          const SizedBox(height: 16),
          // Scanner button
          FloatingActionButton(
            onPressed: () => _startScanning(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.qr_code_scanner),
            heroTag: "scanner",
          ),
        ],
      ),
    );
  }

  void _toggleAdvancedOptions() {
    setState(() {
      _showAdvancedOptions = !_showAdvancedOptions;
    });
  }

  void _addManualItem() async {
    final barcode = _barcodeController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text);

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a barcode')),
      );
      return;
    }

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch,
      barcode: barcode,
      name: 'Manual Entry',
      quantity: quantity,
      price: price,
      createdAt: DateTime.now(),
    );

    await InventoryService.addItem(ref, item);
    
    _clearManualEntryFields();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added successfully')),
    );
  }

  void _clearManualEntryFields() {
    _barcodeController.clear();
    _quantityController.text = '1';
    _priceController.clear();
  }

  void _handleItemAction(InventoryItem item, String action) async {
    switch (action) {
      case 'edit':
        _navigateToItemDetails(item);
        break;
      case 'delete':
        _confirmDelete(item);
        break;
    }
  }

  void _confirmDelete(InventoryItem item) {
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await InventoryService.deleteItem(ref, item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToItemDetails(InventoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(item: item),
      ),
    );
  }

  Future<void> _startScanning() async {
    try {
      await OptimizedDataWedgeService.instance.startScanning((barcode) {
        InventoryService.processBarcode(ref, barcode);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanner started - point at barcode')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start scanner: $e')),
      );
    }
  }
}
