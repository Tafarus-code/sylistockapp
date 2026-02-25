import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'bloc/inventory_bloc.dart';
import 'services/local_storage_service.dart';
import 'models/inventory_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(InventoryItemAdapter());
  
  // Initialize local storage
  final localStorageService = LocalStorageService();
  await localStorageService.init();
  
  runApp(SylistockApp(localStorageService: localStorageService));
}

class SylistockApp extends StatelessWidget {
  final LocalStorageService localStorageService;
  
  const SylistockApp({
    super.key,
    required this.localStorageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sylistock Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: BlocProvider(
        create: (context) => InventoryBloc(),
        child: const ScannerScreen(),
      ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
