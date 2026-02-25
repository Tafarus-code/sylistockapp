import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'bloc/inventory_bloc.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Skip Hive initialization for web testing
  print('Starting Sylistock App (Web Version)');
  
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
        fontFamily: 'Arial', // Use basic system font
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: BlocProvider(
        create: (context) => InventoryBloc(apiService: ApiService()),
        child: const ScannerScreen(),
      ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
