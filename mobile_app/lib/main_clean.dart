import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'widgets/main_navigation.dart';
import 'screens/inventory/clean_category_screen.dart';
import 'screens/bankability_dashboard_screen.dart';
import 'screens/kyc/kyc_dashboard_screen.dart';
import 'screens/insurance/insurance_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/item_details_screen.dart';
import 'screens/reports/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(InventoryItemAdapter());
    Hive.registerAdapter(EnhancedInventoryItemAdapter());
    Hive.registerAdapter(InventoryCategoryAdapter());
    Hive.registerAdapter(SimpleCategoryAdapter());
    Hive.registerAdapter(WorkingCategoryAdapter());
    Hive.registerAdapter(CleanCategoryAdapter());
    
    // Initialize local storage
    final localStorageService = LocalStorageService();
    await localStorageService.init();
    
    // Initialize Phase 2 services
    await NetworkOptimizationService.instance.initialize();
    await What3WordsService.instance.initialize();
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const ProviderScope(
    child: SylistockApp(),
  ));
}

class SylistockApp extends ConsumerWidget {
  const SylistockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Krediti-GN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/dashboard': (context) => const BankabilityDashboardScreen(),
      },
    );
  }
}
