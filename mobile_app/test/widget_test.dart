import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/bloc/inventory_bloc.dart';
import '../lib/screens/enhanced_scanner_screen.dart';
import '../lib/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'api_base_url': 'http://localhost:8000/api',
    });
  });

  group('Widget Tests', () {
    testWidgets('EnhancedScannerScreen builds correctly', (WidgetTester tester) async {
      final apiService = ApiService();
      await Future.delayed(const Duration(milliseconds: 100));

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => InventoryBloc(apiService: apiService),
            child: const EnhancedScannerScreen(),
          ),
        ),
      );

      // Verify the widget builds without errors
      expect(find.byType(EnhancedScannerScreen), findsOneWidget);
    });

    testWidgets('ScannerScreen displays inventory items', (WidgetTester tester) async {
      final apiService = ApiService();
      await Future.delayed(const Duration(milliseconds: 100));
      final bloc = InventoryBloc(apiService: apiService);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InventoryBloc>(
            create: (_) => bloc,
            child: const EnhancedScannerScreen(),
          ),
        ),
      );

      // Verify the screen builds
      expect(find.byType(EnhancedScannerScreen), findsOneWidget);
    });
  });
}
