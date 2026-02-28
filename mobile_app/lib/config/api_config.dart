class ApiConfig {
  // Development
  static const String baseUrl = 'http://localhost:8000';
  
  // Production (Railway)
  // static const String baseUrl = 'https://your-app.railway.app';
  
  // API Endpoints
  static const String inventoryItems = '/api/inventory/items/';
  static const String inventoryCategories = '/api/inventory/categories/';
  static const String inventoryStats = '/api/inventory/stats/';
  static const String inventorySearch = '/api/inventory/items/search/';
  static const String inventoryBulkImport = '/api/inventory/bulk-import/';
  static const String inventoryBulkExport = '/api/inventory/bulk-export/';
  static const String inventoryBackup = '/api/inventory/backup/';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
