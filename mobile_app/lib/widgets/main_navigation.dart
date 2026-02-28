import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../screens/inventory/enhanced_scanner_screen.dart';
import '../screens/inventory/working_category_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const EnhancedScannerScreen(),
    const BankabilityDashboardScreen(),
    const KYCDashboardScreen(),
    const InsuranceDashboardScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.qr_code_scanner,
      label: 'Scanner',
      description: 'Scan inventory items',
    ),
    NavigationItem(
      icon: Icons.account_balance,
      label: 'Bankability',
      description: 'Credit score & reports',
    ),
    NavigationItem(
      icon: Icons.verified_user,
      label: 'KYC',
      description: 'Verification status',
    ),
    NavigationItem(
      icon: Icons.security,
      label: 'Insurance',
      description: 'Policy management',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _navigationItems[_currentIndex].label,
          style: AppTheme.headline5.copyWith(color: AppTheme.onPrimaryColor),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _navigationItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      ),
      
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppTheme.surfaceColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerItems(),
            const Divider(),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(
        'Krediti-GN Merchant',
        style: AppTheme.headline6.copyWith(color: AppTheme.onPrimaryColor),
      ),
      accountEmail: Text(
        'merchant@krediti-gn.com',
        style: AppTheme.bodyText2.copyWith(color: AppTheme.onPrimaryColor.withOpacity(0.8)),
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppTheme.onPrimaryColor,
        child: Icon(
          Icons.store,
          color: AppTheme.primaryColor,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildDrawerItems() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          subtitle: 'Overview of your business',
          onTap: () => _navigateToScreen(0),
        ),
        _buildDrawerItem(
          icon: Icons.qr_code_scanner,
          title: 'Scanner',
          subtitle: 'Scan inventory items',
          onTap: () => _navigateToScreen(0),
        ),
        _buildDrawerItem(
          icon: Icons.inventory,
          title: 'Inventory',
          subtitle: 'Manage your stock',
          onTap: () => _navigateToInventory(),
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

  void _navigateToScreen(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToInventory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkingCategoryScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _navigateToLogistics() {
    // TODO: Navigate to logistics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logistics screen coming soon!')),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToHelp() {
    // TODO: Navigate to help screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help screen coming soon!')),
    );
  }

  void _navigateToAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Krediti-GN',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance),
      children: [
        const Text('Bankability-as-a-Service platform connecting informal merchants with Tier-1 banks.'),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    // TODO: Implement notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon!')),
    );
  }

  void _showSearch(BuildContext context) {
    // TODO: Implement search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search coming soon!')),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String description;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.description,
  });
}
