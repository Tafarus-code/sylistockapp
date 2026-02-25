import '../models/inventory_item.dart';

abstract class InventoryState {
  const InventoryState();
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  final String? lastScannedBarcode;
  final bool isOffline;

  const InventoryLoaded({
    required this.items,
    this.lastScannedBarcode,
    this.isOffline = false,
  });
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);
}

class BarcodeScanSuccess extends InventoryState {
  final String barcode;

  const BarcodeScanSuccess(this.barcode);
}
