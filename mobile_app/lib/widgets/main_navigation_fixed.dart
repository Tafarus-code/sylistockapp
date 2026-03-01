import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../screens/inventory/enhanced_scanner_screen.dart';
import '../screens/inventory/category_management_screen.dart';
import '../screens/bankability_dashboard_screen.dart';
import '../screens/kyc/kyc_dashboard_screen.dart';
import '../screens/insurance/insurance_dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/item_details_screen.dart';
import '../screens/reports/reports_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final List<Widget> _screens = [
    const EnhancedScannerScreen(),
    const BankabilityDashboardScreen(),
    const KYCDashboardScreen(),
    const InsuranceDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Krediti-GN'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              onPressed: () => _scanItem(context),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.qr_code_scanner),
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          const Divider(),
          _buildDrawerMenu(),
          const Divider(),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.account_balance,
              color: AppTheme.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Krediti-GN',
            style: AppTheme.headline6.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Bankability-as-a-Service',
            style: AppTheme.bodyText2.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenu() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.qr_code_scanner,
          title: 'Scanner',
          subtitle: 'Scan inventory items',
          onTap: () => _navigateToScreen(0),
        ),
        _buildDrawerItem(
          icon: Icons.inventory,
          title: 'Categories',
          subtitle: 'Manage categories',
          onTap: () => _navigateToCategories(),
        ),
        _buildDrawerItem(
          icon: Icons.account_balance,
          title: 'Bankability',
          subtitle: 'Credit score & reports',
          onTap: () => _navigateToScreen(1),
        ),
        _buildDrawerItem(
          icon: Icons.verified_user,
          title: 'KYC Verification',
          subtitle: 'Complete your verification',
          onTap: () => _navigateToScreen(2),
        ),
        _buildDrawerItem(
          icon: Icons.security,
          title: 'Insurance',
          subtitle: 'Manage your policies',
          onTap: () => _navigateToScreen(3),
        ),
        _buildDrawerItem(
          icon: Icons.analytics,
          title: 'Reports',
          subtitle: 'View detailed reports',
          onTap: () => _navigateToReports(),
        ),
        _buildDrawerItem(
          icon: Icons.location_on,
          title: 'Logistics',
          subtitle: 'what3words location services',
          onTap: () => _navigateToLogistics(),
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.subtitle1,
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodyText2.copyWith(
          color: AppTheme.onSurfaceColor.withOpacity(0.6),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildDrawerFooter() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: () => _navigateToSettings(),
        ),
        _buildDrawerItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help with the app',
          onTap: () => _navigateToHelp(),
        ),
        _buildDrawerItem(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and info',
          onTap: () => _navigateToAbout(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => _navigateToScreen(index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Bankability',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'KYC',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.security),
          label: 'Insurance',
        ),
      ],
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
    );
  }

  void _navigateToScreen(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help section coming soon!')),
    );
  }

  void _navigateToAbout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('About section coming soon!')),
    );
  }

  void _navigateToLogistics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logistics section coming soon!')),
    );
  }

  void _scanItem(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner functionality coming soon!')),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No new notifications')),
    );
  }
}
