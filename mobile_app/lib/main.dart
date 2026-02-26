import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/enhanced_scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bankability_dashboard_screen.dart';
import 'providers/inventory_provider.dart';
import 'services/local_storage_service.dart';
import 'services/bankability_engine.dart';
import 'services/what3words_service.dart';
import 'services/network_optimization_service.dart';
import 'models/inventory_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(InventoryItemAdapter());
    
    // Initialize local storage
    final localStorageService = LocalStorageService();
    await localStorageService.init();
    
    // Initialize Phase 2 services
    await NetworkOptimizationService.instance.initialize();
    await What3WordsService.instance.initialize();
  } catch (e) {
    print('Initialization error: $e');
  }
  
  runApp(const ProviderScope(child: SylistockApp()));
}

class SylistockApp extends ConsumerWidget {
  const SylistockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Krediti-GN Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto', // Use system font to avoid font loading issues
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const EnhancedScannerScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/dashboard': (context) => const BankabilityDashboardScreen(),
      },
    );
  }
}
