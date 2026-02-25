import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'bloc/inventory_bloc.dart';
import 'services/local_storage_service.dart';
import 'services/auth_service.dart';
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
      home: AuthWrapper(localStorageService: localStorageService),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => BlocProvider(
          create: (context) => InventoryBloc(),
          child: const ScannerScreen(),
        ),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final LocalStorageService localStorageService;
  
  const AuthWrapper({
    super.key,
    required this.localStorageService,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = await AuthService.create();
      final isLoggedIn = await authService.isLoggedIn();
      
      if (mounted) {
        setState(() {
          _isAuthenticated = isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }
    
    return _isAuthenticated 
        ? BlocProvider(
            create: (context) => InventoryBloc(),
            child: const ScannerScreen(),
          )
        : const AuthScreen();
  }
}
