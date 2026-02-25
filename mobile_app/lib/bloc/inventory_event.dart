// Inventory Events
abstract class InventoryEvent {}

class ScanBarcodeEvent extends InventoryEvent {
  final String barcode;
  ScanBarcodeEvent(this.barcode);
}

class LoadInventoryEvent extends InventoryEvent {}

class AddInventoryItemEvent extends InventoryEvent {
  final String barcode;
  final String name;
  final int quantity;

  AddInventoryItemEvent({
    required this.barcode,
    required this.name,
    required this.quantity,
  });
}

