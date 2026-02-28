import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Brand Colors for Krediti-GN
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color primaryDark = Color(0xFF1565C0); // Dark Blue
  static const Color primaryLight = Color(0xFF42A5F5); // Light Blue
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color onPrimaryColor = Color(0xFFFFFFFF); // White
  static const Color onSurfaceColor = Color(0xFF212121); // Dark Gray
  static const Color dividerColor = Color(0xFFE0E0E0); // Light Gray
  
  // Banking-specific colors
  static const Color bankColor = Color(0xFF2E7D32); // Bank Green
  static const Color insuranceColor = Color(0xFF1976D2); // Insurance Blue
  static const Color kycColor = Color(0xFF7B1FA2); // KYC Purple
  static const Color riskColor = Color(0xFFFF6F00); // Risk Orange
  
  // Typography
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
    letterSpacing: -0.25,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );
  
  static const TextStyle headline5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );
  
  static const TextStyle headline6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );
  
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: onSurfaceColor,
  );
  
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );
  
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: onSurfaceColor,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurfaceColor,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: onPrimaryColor,
    letterSpacing: 0.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: onSurfaceColor,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: onSurfaceColor,
    letterSpacing: 1.5,
  );
  
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: accentColor,
        secondaryContainer: Color(0xFFB2EBF2),
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSurfaceColor,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        onError: onPrimaryColor,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onPrimaryColor,
        ),
        iconTheme: IconThemeData(
          color: onPrimaryColor,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: button,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: button,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: button,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(color: onSurfaceColor),
        hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: onPrimaryColor,
        elevation: 4,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        selectedColor: primaryColor,
        disabledColor: dividerColor,
        labelStyle: const TextStyle(color: onSurfaceColor),
        secondaryLabelStyle: const TextStyle(color: onPrimaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: headline1,
        displayMedium: headline2,
        displaySmall: headline3,
        headlineLarge: headline4,
        headlineMedium: headline5,
        headlineSmall: headline6,
        titleLarge: subtitle1,
        titleMedium: subtitle2,
        bodyLarge: bodyText1,
        bodyMedium: bodyText2,
        labelLarge: button,
        bodySmall: caption,
        labelSmall: overline,
      ),
    );
  }
  
  // Dark Theme (optional for future implementation)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: primaryColor,
        secondary: accentColor,
        secondaryContainer: Color(0xFF006064),
        surface: Color(0xFF121212),
        background: Color(0xFF121212),
        error: errorColor,
        onPrimary: onSurfaceColor,
        onSecondary: onSurfaceColor,
        onSurface: onPrimaryColor,
        onBackground: onPrimaryColor,
        onError: onPrimaryColor,
      ),
    );
  }
  
  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successColor, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningColor, Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorColor, Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Custom Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  // Custom Border Radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(4));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(16));
  
  // Custom Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  
  // Custom Icon Sizes
  static const double iconSize16 = 16.0;
  static const double iconSize20 = 20.0;
  static const double iconSize24 = 24.0;
  static const double iconSize32 = 32.0;
  static const double iconSize48 = 48.0;
  static const double iconSize64 = 64.0;
}
