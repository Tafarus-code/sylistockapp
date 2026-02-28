import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../screens/inventory/enhanced_scanner_screen.dart';
import '../screens/bankability_dashboard_screen.dart';
import '../screens/kyc/kyc_dashboard_screen.dart';
import '../screens/insurance/insurance_dashboard_screen.dart';
import '../screens/settings_screen.dart';
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
    const CategoriesScreen(),
    const BankabilityDashboardScreen(),
    const KYCDashboardScreen(),
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
      floatingActionButton: _currentIndex == 1 
          ? FloatingActionButton(
              onPressed: () => _scanItem(context),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
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
          icon: Icons.category,
          title: 'Categories',
          subtitle: 'Manage categories',
          onTap: () => _navigateToScreen(1),
        ),
        _buildDrawerItem(
          icon: Icons.account_balance,
          title: 'Bankability',
          subtitle: 'Credit score & reports',
          onTap: () => _navigateToScreen(2),
        ),
        _buildDrawerItem(
          icon: Icons.verified_user,
          title: 'KYC Verification',
          subtitle: 'Complete your verification',
          onTap: () => _navigateToScreen(3),
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
          subtitle: 'Get help with app',
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
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Bankability',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'KYC',
        ),
      ],
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
    );
  }

  void _navigateToScreen(int index) {
    setState(() => _currentIndex = index);
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
      const SnackBar(content: Text('Use floating + button to add categories!')),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No new notifications')),
    );
  }
}

@HiveType(typeId: 8)
class WorkingCategory {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime createdAt;

  WorkingCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
}

class WorkingCategoryAdapter extends TypeAdapter<WorkingCategory> {
  @override
  final int typeId = 8;

  @override
  WorkingCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      final value = reader.read();
      fields[fieldId] = value;
    }

    return WorkingCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdAt: DateTime.parse(fields[3] as String),
    );
  }

  @override
  void write(BinaryWriter writer, WorkingCategory obj) {
    writer.writeByte(4);
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.createdAt.toIso8601String());
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Box<WorkingCategory> _categoryBox;
  List<WorkingCategory> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      print('Starting Hive initialization...');
      
      // Register adapter
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(WorkingCategoryAdapter());
        print('WorkingCategoryAdapter registered');
      }
      
      // Open box
      _categoryBox = await Hive.openBox<WorkingCategory>('working_categories');
      print('Working category box opened successfully');
      
      // Load existing categories
      await _loadCategories();
      
      setState(() {});
    } catch (e) {
      print('Error initializing Hive: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hive initialization error: $e')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final keys = _categoryBox.keys;
      _categories.clear();
      
      for (final key in keys) {
        final category = _categoryBox.get(key);
        if (category != null) {
          _categories.add(category);
        }
      }
      
      print('Loaded ${_categories.length} categories');
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addCategory,
                          child: const Text('Add Category'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loadCategories,
                          child: const Text('Refresh Categories'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _categories.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No categories yet. Add one!',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap the + button to create your first category',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.category, color: AppTheme.primaryColor),
                                title: Text(category.name),
                                subtitle: category.description != null 
                                    ? Text(category.description!)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editCategory(category),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteCategory(category.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addCategory() async {
    final category = WorkingCategory(
      id: const Uuid().v4(),
      name: 'Category ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Created at ${DateTime.now()}',
      createdAt: DateTime.now(),
    );

    try {
      await _categoryBox.put(category.id, category);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );
      }
    } catch (e) {
      print('Error adding category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _categoryBox.delete(id);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }

  void _editCategory(WorkingCategory category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updatedCategory = WorkingCategory(
                  id: category.id,
                  name: nameController.text,
                  description: descriptionController.text.isEmpty 
                      ? null 
                      : descriptionController.text,
                  createdAt: category.createdAt,
                );

                try {
                  await _categoryBox.put(updatedCategory.id, updatedCategory);
                  await _loadCategories();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category updated successfully!')),
                    );
                  }
                } catch (e) {
                  print('Error updating category: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating category: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final category = WorkingCategory(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  description: descriptionController.text.isEmpty 
                      ? null 
                      : descriptionController.text,
                  createdAt: DateTime.now(),
                );

                try {
                  await _categoryBox.put(category.id, category);
                  await _loadCategories();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category added successfully!')),
                    );
                  }
                } catch (e) {
                  print('Error adding category: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding category: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
