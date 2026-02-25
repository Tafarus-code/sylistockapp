import 'package:flutter_bloc/flutter_bloc.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/connectivity_service.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiService _apiService;
  final LocalStorageService? _localStorageService;
  final ConnectivityService? _connectivityService;
  final List<InventoryItem> _items = [];

  InventoryBloc({
    ApiService? apiService,
    LocalStorageService? localStorageService,
    ConnectivityService? connectivityService,
  }) : _apiService = apiService ?? ApiService(),
       _localStorageService = localStorageService,
       _connectivityService = connectivityService,
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
      // Initialize local storage if available
      if (_localStorageService != null) {
        await _localStorageService!.init();
      }
      
      // Check connectivity if service is available
      bool isConnected;
      if (_connectivityService != null) {
        isConnected = await _connectivityService!.isConnected();
      } else {
        isConnected = true; // Default to online if service not available
      }
      
      if (isConnected) {
        // Try to fetch from API first
        try {
          final items = await _apiService.fetchInventory();
          _items.clear();
          _items.addAll(items);
          
          // Save to local storage if available
          if (_localStorageService != null) {
            await _localStorageService!.saveInventoryItems(items);
            await _localStorageService!.saveLastSyncTime(DateTime.now());
          }
          
          emit(InventoryLoaded(items: List.from(_items)));
        } catch (e) {
          // If API fails, try to load from local storage
          if (_localStorageService != null) {
            final localItems = _localStorageService!.getInventoryItems();
            if (localItems.isNotEmpty) {
              _items.clear();
              _items.addAll(localItems);
              emit(InventoryLoaded(
                items: List.from(_items),
                isOffline: true,
              ));
              return;
            }
          }
          emit(InventoryError('Failed to load inventory: ${e.toString()}'));
        }
      } else {
        // Load from local storage when offline
        if (_localStorageService != null) {
          final localItems = _localStorageService!.getInventoryItems();
          _items.clear();
          _items.addAll(localItems);
          emit(InventoryLoaded(
            items: List.from(_items),
            isOffline: true,
          ));
        } else {
          emit(InventoryLoaded(items: [], isOffline: true));
        }
      }
    } catch (e) {
      emit(InventoryError('Failed to load inventory: ${e.toString()}'));
    }
  }

  Future<void> _onScanBarcode(
    ScanBarcodeEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      bool isConnected;
      if (_connectivityService != null) {
        isConnected = await _connectivityService!.isConnected();
      } else {
        isConnected = true; // Default to online if service not available
      }
      
      if (isConnected) {
        // Send barcode to backend
        await _apiService.sendBarcode(event.barcode);
        
        // Update UI with scanned barcode
        emit(BarcodeScanSuccess(event.barcode));
        
        // Reload inventory after scan
        add(LoadInventoryEvent());
      } else {
        // Store barcode for later sync
        // You could implement a queue system here
        emit(BarcodeScanSuccess(event.barcode));
        emit(const InventoryError('Offline: Barcode will sync when connection is restored'));
      }
    } catch (e) {
      emit(InventoryError('Failed to process barcode: ${e.toString()}'));
    }
  }

  Future<void> _onAddInventoryItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      bool isConnected;
      if (_connectivityService != null) {
        isConnected = await _connectivityService!.isConnected();
      } else {
        isConnected = true; // Default to online if service not available
      }
      
      InventoryItem newItem;
      
      if (isConnected) {
        newItem = await _apiService.addInventoryItem(
          barcode: event.barcode,
          name: event.name,
          quantity: event.quantity,
        );
      } else {
        // Create item locally for offline mode
        newItem = InventoryItem(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          barcode: event.barcode,
          name: event.name,
          quantity: event.quantity,
          createdAt: DateTime.now(),
        );
        if (_localStorageService != null) {
          await _localStorageService!.addInventoryItem(newItem);
        }
      }

      _items.add(newItem);
      emit(InventoryLoaded(
        items: List.from(_items),
        lastScannedBarcode: event.barcode,
        isOffline: !isConnected,
      ));
    } catch (e) {
      emit(InventoryError('Failed to add item: ${e.toString()}'));
    }
  }
}

