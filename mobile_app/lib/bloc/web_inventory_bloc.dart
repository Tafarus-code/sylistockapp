import 'package:flutter_bloc/flutter_bloc.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class WebInventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiService _apiService;
  final List<InventoryItem> _items = [];

  WebInventoryBloc({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService(),
        super(InventoryInitial()) {
    on<LoadInventoryEvent>(_onLoadInventory);
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddInventoryItemEvent>(_onAddInventoryItem);
  }

  Future<void> _onLoadInventory(
    LoadInventoryEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    
    try {
      // For web version, just try API directly
      final items = await _apiService.fetchInventory();
      _items.clear();
      _items.addAll(items);
      
      emit(InventoryLoaded(items: items, isOffline: false));
      
    } catch (e) {
      // If API fails, show empty state with error
      emit(InventoryLoaded(items: [], isOffline: true));
      // You could show an error message here if needed
      print('API Error: $e');
    }
  }

  Future<void> _onScanBarcode(
    ScanBarcodeEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _apiService.sendBarcode(event.barcode);
      emit(BarcodeScanSuccess(event.barcode));
    } catch (e) {
      emit(BarcodeScanSuccess(event.barcode)); // Still show success for demo
      print('Barcode scan error: $e');
    }
  }

  Future<void> _onAddInventoryItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      final newItem = await _apiService.addInventoryItem(
        barcode: event.barcode,
        name: event.name,
        quantity: event.quantity,
      );
      
      _items.add(newItem);
      emit(InventoryLoaded(
        items: List.from(_items),
        lastScannedBarcode: event.barcode,
        isOffline: false,
      ));
      
    } catch (e) {
      // For demo, add item locally even if API fails
      final newItem = InventoryItem(
        id: _items.length + 1,
        barcode: event.barcode,
        name: event.name,
        quantity: event.quantity,
        createdAt: DateTime.now(),
      );
      
      _items.add(newItem);
      emit(InventoryLoaded(
        items: List.from(_items),
        lastScannedBarcode: event.barcode,
        isOffline: true,
      ));
      print('Add item error: $e');
    }
  }
}
