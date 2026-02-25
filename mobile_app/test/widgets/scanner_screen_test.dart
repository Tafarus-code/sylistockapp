import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/screens/scanner_screen.dart';
import '../../lib/bloc/inventory_bloc.dart';
import '../../lib/bloc/inventory_state.dart';
import '../../lib/models/inventory_item.dart';

void main() {
  group('ScannerScreen Widget Tests', () {
    late InventoryBloc inventoryBloc;

    setUp(() {
      inventoryBloc = InventoryBloc();
    });

    tearDown(() {
      inventoryBloc.close();
    });

    testWidgets('ScannerScreen builds correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      expect(find.text('Sylistock Scanner'), findsOneWidget);
      expect(find.text('Inventory Scanner'), findsOneWidget);
      expect(find.text('Scan barcodes and keep inventory in sync.'), findsOneWidget);
    });

    testWidgets('ScannerScreen shows settings button', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('ScannerScreen shows manual entry button', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      expect(find.text('Manual Entry'), findsOneWidget);
    });

    testWidgets('ScannerScreen shows refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('ScannerScreen shows search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search items by name or barcode...'), findsOneWidget);
    });

    testWidgets('ScannerScreen shows empty state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      expect(find.text('Press refresh to load inventory'), findsOneWidget);
    });

    testWidgets('Manual entry dialog appears when button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: inventoryBloc,
          child: const MaterialApp(
            home: ScannerScreen(
              enableZebra: false,
              autoLoadInventory: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Manual Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Manual Barcode Entry'), findsOneWidget);
      expect(find.text('Enter Barcode'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
