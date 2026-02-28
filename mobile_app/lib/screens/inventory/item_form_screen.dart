import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/enhanced_inventory_service.dart';
import '../../models/enhanced_inventory_item.dart';
import '../inventory/category_selection_screen.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final EnhancedInventoryItem? item;
  final String? initialBarcode;
  
  const ItemFormScreen({
    Key? key,
    this.item,
    this.initialBarcode,
  }) : super(key: key);

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _qrCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCategoryId;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  String? _imageUrl;
  final List<String> _tags = [];
  bool _isActive = true;
  
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.item != null) {
      final item = widget.item!;
      _nameController.text = item.name;
      _barcodeController.text = item.barcode ?? '';
      _qrCodeController.text = item.qrCode ?? '';
      _descriptionController.text = item.description ?? '';
      _quantityController.text = item.quantity.toString();
      _unitPriceController.text = item.unitPrice.toString();
      _sellingPriceController.text = item.sellingPrice?.toString() ?? '';
      _supplierController.text = item.supplier ?? '';
      _locationController.text = item.location ?? '';
      _weightController.text = item.weight?.toString() ?? '';
      _dimensionsController.text = item.dimensions ?? '';
      _minStockController.text = item.minStockLevel?.toString() ?? '';
      _maxStockController.text = item.maxStockLevel?.toString() ?? '';
      _notesController.text = item.notes ?? '';
      _selectedCategoryId = item.categoryId;
      _purchaseDate = item.purchaseDate;
      _expiryDate = item.expiryDate;
      _imageUrl = item.imageUrl;
      _tags.addAll(item.tags);
      _isActive = item.isActive;
    } else if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveItem,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                    _buildInventorySection(),
                    const SizedBox(height: 24),
                    _buildDatesSection(),
                    const SizedBox(height: 24),
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    _buildTagsSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'Enter item name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter item description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Category'),
              subtitle: Text(_selectedCategoryId ?? 'Select category'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectCategory,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      hintText: 'Scan or enter barcode',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qrCodeController,
              decoration: const InputDecoration(
                labelText: 'QR Code',
                hintText: 'Enter QR code',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
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
            TextFormField(
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price *',
                hintText: '0.00',
                prefixText: '₵',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter unit price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellingPriceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                hintText: '0.00',
                prefixText: '₵',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Supplier',
                hintText: 'Enter supplier name',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
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
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Level',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxStockController,
                    decoration: const InputDecoration(
                      labelText: 'Max Stock Level',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Storage location',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: '0.0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dimensionsController,
                    decoration: const InputDecoration(
                      labelText: 'Dimensions (LxWxH)',
                      hintText: '0x0x0',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
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
            ListTile(
              title: const Text('Purchase Date'),
              subtitle: Text(_purchaseDate != null 
                  ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                  : 'Select purchase date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectPurchaseDate,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Expiry Date'),
              subtitle: Text(_expiryDate != null 
                  ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                  : 'Select expiry date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectExpiryDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image',
              style: AppTheme.headline6,
            ),
            const SizedBox(height: 16),
            if (_imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
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
              children: _tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
              )).toList(),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
              label: const Text('Add Tag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
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
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Enter any additional notes',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Item is currently active in inventory'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              widget.item == null ? 'Add Item' : 'Update Item',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.errorColor),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ],
    );
  }

  void _selectCategory() async {
    final category = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CategorySelectionScreen()),
    );
    if (category != null) {
      setState(() => _selectedCategoryId = category);
    }
  }

  void _scanBarcode() {
    // TODO: Implement barcode scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode scanning coming soon!')),
    );
  }

  void _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _purchaseDate = date);
    }
  }

  void _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  void _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // TODO: Upload image and get URL
      setState(() => _imageUrl = image.path);
    }
  }

  void _pickImageFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Upload image and get URL
      setState(() => _imageUrl = image.path);
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Tag name',
            hintText: 'Enter tag name',
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty && !_tags.contains(value)) {
              setState(() => _tags.add(value));
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final inventoryService = ref.read(enhancedInventoryServiceProvider);
      
      final item = EnhancedInventoryItem(
        id: widget.item?.id,
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        qrCode: _qrCodeController.text.isEmpty ? null : _qrCodeController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        categoryId: _selectedCategoryId!,
        quantity: int.parse(_quantityController.text),
        unitPrice: double.parse(_unitPriceController.text),
        sellingPrice: _sellingPriceController.text.isEmpty 
            ? null 
            : double.parse(_sellingPriceController.text),
        supplier: _supplierController.text.isEmpty ? null : _supplierController.text,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        tags: _tags,
        isActive: _isActive,
        imageUrl: _imageUrl,
        weight: _weightController.text.isEmpty ? null : double.parse(_weightController.text),
        dimensions: _dimensionsController.text.isEmpty ? null : _dimensionsController.text,
        minStockLevel: _minStockController.text.isEmpty ? null : int.parse(_minStockController.text),
        maxStockLevel: _maxStockController.text.isEmpty ? null : int.parse(_maxStockController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.item == null) {
        await inventoryService.createItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      } else {
        await inventoryService.updateItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
