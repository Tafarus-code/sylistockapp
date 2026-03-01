import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'widgets/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bankability_dashboard_screen.dart';
import 'services/local_storage_service.dart';
import 'services/network_optimization_service.dart';
import 'services/what3words_service.dart';
import 'services/enhanced_inventory_service.dart';
import 'services/auth_service.dart';
import 'config/api_config.dart';
import 'models/inventory_item.dart';
import 'models/enhanced_inventory_item.dart';
import 'models/test_category.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load saved server URL before anything else
    await ApiConfig.loadSavedUrl();

    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(InventoryItemAdapter());
    Hive.registerAdapter(EnhancedInventoryItemAdapter());
    Hive.registerAdapter(InventoryCategoryAdapter());
    Hive.registerAdapter(TestCategoryAdapter());
    Hive.registerAdapter(WorkingCategoryAdapter());

    // Initialize enhanced inventory service
    final enhancedInventoryService = EnhancedInventoryService();
    await enhancedInventoryService.initialize();

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
      title: 'Krediti-GN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/dashboard': (context) =>
            const BankabilityDashboardScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

/// Checks if user is logged in; shows LoginScreen or MainNavigation
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance,
                      size: 64, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}
