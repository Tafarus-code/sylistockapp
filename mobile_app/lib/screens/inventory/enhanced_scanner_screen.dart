import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/action_button.dart';
import '../../services/enhanced_inventory_service.dart';
import '../../models/enhanced_inventory_item.dart';
import 'item_form_screen.dart';
import 'inventory_list_screen.dart';
import 'category_management_screen.dart';

class EnhancedScannerScreen extends ConsumerStatefulWidget {
  const EnhancedScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedScannerScreen> createState() => _EnhancedScannerScreenState();
}

class _EnhancedScannerScreenState extends ConsumerState<EnhancedScannerScreen> {
  bool _isScanning = false;
  bool _useCamera = false;
  String? _lastScannedCode;
  int _scanCount = 0;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      setState(() => _useCamera = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Scanner'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_useCamera ? Icons.qr_code_scanner : Icons.camera_alt),
            onPressed: _toggleScannerMode,
            tooltip: _useCamera ? 'Use DataWedge' : 'Use Camera',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _navigateToInventoryList,
            tooltip: 'View Inventory',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: _useCamera ? _buildCameraScanner() : _buildDataWedgeScanner(),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Items Scanned', '$_scanCount', Icons.qr_code),
            _buildStatItem('Mode', _useCamera ? 'Camera' : 'DataWedge', Icons.settings),
            _buildStatItem('Last Code', _lastScannedCode?.substring(0, 8) ?? 'None', Icons.history),
          ],
        ),
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

  Widget _buildCameraScanner() {
    return MobileScanner(
      controller: _scannerController,
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            _handleScannedCode(barcode.rawValue!);
            break;
          }
        }
      },
      errorBuilder: (context, error, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: AppTheme.headline6.copyWith(color: AppTheme.errorColor),
              ),
              Text(
                'Unable to access camera. Please check permissions.',
                style: AppTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ActionButton(
                text: 'Use DataWedge',
                onPressed: () => setState(() => _useCamera = false),
                icon: Icons.qr_code_scanner,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataWedgeScanner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            color: AppTheme.primaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'DataWedge Scanner',
            style: AppTheme.headline5.copyWith(color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Zebra TC26 scanner for high-speed scanning',
            style: AppTheme.bodyText2.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ActionButton(
            text: 'Switch to Camera',
            onPressed: () => setState(() => _useCamera = true),
            icon: Icons.camera_alt,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          if (_lastScannedCode != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor),
              ),
              child: Column(
                children: [
                  Text(
                    'Last Scanned',
                    style: AppTheme.subtitle2.copyWith(color: AppTheme.successColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastScannedCode!,
                    style: AppTheme.bodyText1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  text: 'Add Item',
                  onPressed: _navigateToAddItem,
                  icon: Icons.add,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ActionButton(
                  text: 'Categories',
                  onPressed: _navigateToCategories,
                  icon: Icons.category,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToInventoryList,
              icon: const Icon(Icons.list),
              label: const Text('View All Items'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String code) {
    if (!mounted) return;
    
    setState(() {
      _lastScannedCode = code;
      _scanCount++;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show dialog with options
    _showScannedItemDialog(code);
  }

  void _showScannedItemDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Scanned'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Barcode/QR Code:',
              style: AppTheme.subtitle2,
            ),
            const SizedBox(height: 4),
            Text(
              code,
              style: AppTheme.bodyText1.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like to do?',
              style: AppTheme.subtitle2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAddItemWithCode(code);
            },
            child: const Text('Add Item'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchForItem(code);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _toggleScannerMode() {
    setState(() {
      _useCamera = !_useCamera;
    });
  }

  void _navigateToAddItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemFormScreen()),
    );
  }

  void _navigateToAddItemWithCode(String code) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemFormScreen(initialBarcode: code)),
    );
  }

  void _navigateToInventoryList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InventoryListScreen()),
    );
  }

  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
    );
  }

  void _searchForItem(String code) async {
    final inventoryService = ref.read(enhancedInventoryServiceProvider);
    final item = await inventoryService.getItemByBarcode(code);
    
    if (item != null) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found: ${item.name}'),
          backgroundColor: AppTheme.successColor,
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _navigateToItemDetails(item),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item not found: $code'),
          backgroundColor: AppTheme.warningColor,
          action: SnackBarAction(
            label: 'Add',
            onPressed: () => _navigateToAddItemWithCode(code),
          ),
        ),
      );
    }
  }

  void _navigateToItemDetails(EnhancedInventoryItem item) {
    // TODO: Navigate to item details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item details for ${item.name}')),
    );
  }
}
