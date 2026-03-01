import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String? _overrideBaseUrl;

  /// The base URL for the Django backend.
  ///
  /// Priority:
  /// 1. User-configured URL from Settings (saved in SharedPreferences)
  /// 2. Platform default:
  ///    - Web → http://localhost:8000
  ///    - Otherwise → http://localhost:8000
  ///
  /// For Android emulator: set URL to http://10.0.2.2:8000 in Settings.
  /// For physical device: set URL to http://<your-pc-ip>:8000 in Settings.
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    return 'http://localhost:8000';
  }

  /// Load the user-configured URL from SharedPreferences.
  /// Call this once at app startup.
  static Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _overrideBaseUrl = prefs.getString('api_base_url');
  }

  /// Save a new base URL (from the Settings screen).
  static Future<void> setBaseUrl(String url) async {
    // Remove trailing slash
    final cleaned = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _overrideBaseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', cleaned);
  }

  // ─── Authentication ───
  static const String authRegister = '/api/auth/register/';
  static const String authLogin = '/api/auth/login/';
  static const String authLogout = '/api/auth/logout/';
  static const String authProfile = '/api/auth/profile/';

  // ─── Inventory (under /inventory/ prefix) ───
  static const String items = '/inventory/items/';
  static const String addItem = '/inventory/items/add/';
  static String updateItem(int id) => '/inventory/items/update/$id/';
  static String removeItem(int id) => '/inventory/items/remove/$id/';
  static const String searchItems = '/inventory/items/search/';
  static String itemDetails(int id) => '/inventory/items/$id/';
  static const String inventoryHistory = '/inventory/items/history/';
  static const String scanProcess = '/inventory/scan/';

  // ─── Alerts ───
  static const String lowStockAlerts = '/inventory/alerts/low-stock/';
  static const String alertThreshold = '/inventory/alerts/threshold/';

  // ─── Categories ───
  static const String categories = '/inventory/categories/';
  static const String createCategory = '/inventory/categories/create/';
  static String updateCategory(int id) =>
      '/inventory/categories/$id/update/';
  static String deleteCategory(int id) =>
      '/inventory/categories/$id/delete/';

  // ─── Reports ───
  static const String salesReport = '/inventory/reports/sales/';
  static const String merchantPerformance =
      '/inventory/reports/performance/';

  // ─── Bulk Operations ───
  static const String bulkImport = '/inventory/bulk/import/';
  static const String bulkExport = '/inventory/bulk/export/';
  static const String bulkUpdate = '/inventory/bulk/update/';

  // ─── KYC ───
  static const String kycInitiate = '/inventory/kyc/initiate/';
  static const String kycUploadDocument =
      '/inventory/kyc/upload-document/';
  static const String kycAddBankAccount =
      '/inventory/kyc/add-bank-account/';
  static const String kycComplianceChecks =
      '/inventory/kyc/compliance-checks/';
  static const String kycEvaluate = '/inventory/kyc/evaluate/';
  static String kycStatus(String id) => '/inventory/kyc/status/$id/';
  static String kycDocuments(String id) =>
      '/inventory/kyc/documents/$id/';
  static String kycBankAccounts(String id) =>
      '/inventory/kyc/bank-accounts/$id/';

  // ─── Insurance ───
  static const String insuranceCalculatePremium =
      '/inventory/insurance/calculate-premium/';
  static const String insuranceAssessRisk =
      '/inventory/insurance/assess-risk/';
  static const String insuranceCreatePolicy =
      '/inventory/insurance/create-policy/';
  static const String insuranceSubmitClaim =
      '/inventory/insurance/submit-claim/';
  static String insurancePolicyDetails(String id) =>
      '/inventory/insurance/policy/$id/';
  static String insuranceMerchantPolicies(int id) =>
      '/inventory/insurance/merchant/$id/policies/';

  // ─── Timeouts ───
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // ─── Headers ───
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
