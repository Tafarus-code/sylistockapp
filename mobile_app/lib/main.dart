import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/enhanced_scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'bloc/inventory_bloc.dart';
import 'services/local_storage_service.dart';
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
  } catch (e) {
    print('Initialization error: $e');
  }
  
  runApp(const SylistockApp());
}

class SylistockApp extends StatelessWidget {
  const SylistockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sylistock Scanner',
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
      home: BlocProvider(
        create: (context) => InventoryBloc(),
        child: EnhancedScannerScreen(),
      ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
