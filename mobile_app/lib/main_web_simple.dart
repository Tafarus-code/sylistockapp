import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/web_scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'bloc/web_inventory_bloc.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting Sylistock App (Web Version - No Local Storage)');
  
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
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: BlocProvider(
        create: (context) => WebInventoryBloc(apiService: ApiService()),
        child: const WebScannerScreen(),
      ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
