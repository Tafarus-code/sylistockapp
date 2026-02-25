// import 'package:flutter_test/flutter_test.dart';
// import 'package:bloc_test/bloc_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import '../lib/bloc/inventory_bloc.dart';
// import '../lib/bloc/inventory_event.dart';
// import '../lib/bloc/inventory_state.dart';
// import '../lib/models/inventory_item.dart';
// import '../lib/services/api_service.dart';
// import '../lib/services/local_storage_service.dart';
// import '../lib/services/connectivity_service.dart';
//
// import 'inventory_bloc_test.mocks.dart';
//
// @GenerateMocks([ApiService, LocalStorageService, ConnectivityService])
// void main() {
//   group('InventoryBloc Tests', () {
//     late MockApiService mockApiService;
//     late MockLocalStorageService mockLocalStorageService;
//     late MockConnectivityService mockConnectivityService;
//     late InventoryBloc inventoryBloc;
//
//     setUp(() {
//       mockApiService = MockApiService();
//       mockLocalStorageService = MockLocalStorageService();
//       mockConnectivityService = MockConnectivityService();
//       inventoryBloc = InventoryBloc();
//     });
//
//     tearDown(() {
//       inventoryBloc.close();
//     });
//
//     test('initial state is InventoryInitial', () {
//       expect(inventoryBloc.state, equals(InventoryInitial()));
//     });
//
//     group('LoadInventoryEvent', () {
//       final testItems = [
//         InventoryItem(
//           id: 1,
//           barcode: '123456',
//           name: 'Test Item',
//           quantity: 10,
//           createdAt: DateTime.now(),
//         ),
//       ];
//
//       blocTest<InventoryBloc, InventoryState>(
//         'emits [InventoryLoading, InventoryLoaded] when load succeeds online',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => true);
//           when(mockLocalStorageService.init()).thenAnswer((_) async {});
//           when(mockApiService.fetchInventory()).thenAnswer((_) async => testItems);
//           when(mockLocalStorageService.saveInventoryItems(testItems)).thenAnswer((_) async {});
//           when(mockLocalStorageService.saveLastSyncTime(any)).thenAnswer((_) async {});
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(LoadInventoryEvent()),
//         expect: () => [
//           InventoryLoading(),
//           InventoryLoaded(items: testItems),
//         ],
//       );
//
//       blocTest<InventoryBloc, InventoryState>(
//         'emits [InventoryLoading, InventoryLoaded] when offline with cached data',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => false);
//           when(mockLocalStorageService.init()).thenAnswer((_) async {});
//           when(mockLocalStorageService.getInventoryItems()).thenReturn(testItems);
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(LoadInventoryEvent()),
//         expect: () => [
//           InventoryLoading(),
//           InventoryLoaded(items: testItems, isOffline: true),
//         ],
//       );
//
//       blocTest<InventoryBloc, InventoryState>(
//         'emits [InventoryLoading, InventoryError] when load fails',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => true);
//           when(mockLocalStorageService.init()).thenAnswer((_) async {});
//           when(mockApiService.fetchInventory()).thenThrow(Exception('Network error'));
//           when(mockLocalStorageService.getInventoryItems()).thenReturn([]);
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(LoadInventoryEvent()),
//         expect: () => [
//           InventoryLoading(),
//           InventoryError('Failed to load inventory: Exception: Network error'),
//         ],
//       );
//     });
//
//     group('ScanBarcodeEvent', () {
//       const testBarcode = '123456789';
//
//       blocTest<InventoryBloc, InventoryState>(
//         'emits [BarcodeScanSuccess] when scan succeeds online',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => true);
//           when(mockApiService.sendBarcode(testBarcode)).thenAnswer((_) async {});
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(const ScanBarcodeEvent(testBarcode)),
//         expect: () => [
//           const BarcodeScanSuccess(testBarcode),
//         ],
//       );
//
//       blocTest<InventoryBloc, InventoryState>(
//         'emits [BarcodeScanSuccess, InventoryError] when offline',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => false);
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(const ScanBarcodeEvent(testBarcode)),
//         expect: () => [
//           const BarcodeScanSuccess(testBarcode),
//           const InventoryError('Offline: Barcode will sync when connection is restored'),
//         ],
//       );
//     });
//
//     group('AddInventoryItemEvent', () {
//       const testEvent = AddInventoryItemEvent(
//         barcode: '123456',
//         name: 'New Item',
//         quantity: 5,
//       );
//
//       final newItem = InventoryItem(
//         id: 1,
//         barcode: '123456',
//         name: 'New Item',
//         quantity: 5,
//         createdAt: DateTime.now(),
//       );
//
//       blocTest<InventoryBloc, InventoryState>(
//         'adds item successfully online',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => true);
//           when(mockApiService.addInventoryItem(
//             barcode: '123456',
//             name: 'New Item',
//             quantity: 5,
//           )).thenAnswer((_) async => newItem);
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(testEvent),
//         expect: () => [
//           InventoryLoaded(
//             items: [newItem],
//             lastScannedBarcode: '123456',
//             isOffline: false,
//           ),
//         ],
//       );
//
//       blocTest<InventoryBloc, InventoryState>(
//         'adds item successfully offline',
//         build: () {
//           when(mockConnectivityService.isConnected()).thenAnswer((_) async => false);
//           when(mockLocalStorageService.addInventoryItem(any)).thenAnswer((_) async {});
//           return inventoryBloc;
//         },
//         act: (bloc) => bloc.add(testEvent),
//         expect: () => [
//           predicate<InventoryLoaded>((state) =>
//               state.items.length == 1 &&
//               state.items.first.barcode == '123456' &&
//               state.items.first.name == 'New Item' &&
//               state.isOffline == true),
//         ],
//       );
//     });
//   });
// }
