import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

/// 4G Network Optimization Service for Krediti-GN
/// Optimizes API calls for 4G LTE stability in Guinea
class NetworkOptimizationService {
  static NetworkOptimizationService? _instance;
  static NetworkOptimizationService get instance => _instance ??= NetworkOptimizationService._();
  
  NetworkOptimizationService._();
  
  final List<QueuedRequest> _syncQueue = [];
  final Map<String, DateTime> _lastSyncAttempts = {};
  Timer? _syncTimer;
  bool _isOnline = true;
  ConnectivityResult? _currentConnectivity;
  late Dio _dio;
  
  /// Initialize network optimization
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    _startBackgroundSync();
    _loadQueueFromStorage();
    
    // Initialize Dio for HTTP requests
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'Krediti-GN/1.0',
        'Accept-Encoding': 'gzip, deflate',
      },
    ));
    
    print('Network optimization service initialized');
  }
  
  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      _currentConnectivity = connectivity;
      _isOnline = connectivity != ConnectivityResult.none;
      
      print('Connectivity status: $_isOnline ($connectivity)');
    } catch (e) {
      print('Error checking connectivity: $e');
      _isOnline = false;
    }
  }
  
  /// Monitor connectivity changes
  void _startConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _currentConnectivity = result;
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        print('Connection restored - starting sync');
        _processSyncQueue();
      } else if (wasOnline && !_isOnline) {
        print('Connection lost - enabling offline mode');
      }
    });
  }
  
  /// Start background sync timer
  void _startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && _syncQueue.isNotEmpty) {
        _processSyncQueue();
      }
    });
  }
  
  /// Add request to sync queue with 4G optimization
  Future<void> queueRequest({
    required String endpoint,
    required Map<String, dynamic> data,
    required String method,
    Map<String, String>? headers,
    int priority = 0,
  }) async {
    // Compress data for 4G efficiency
    final compressedData = _compressData(data);
    
    final request = QueuedRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      endpoint: endpoint,
      data: compressedData,
      method: method,
      headers: headers,
      priority: priority,
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    
    _syncQueue.add(request);
    _sortQueueByPriority();
    await _saveQueueToStorage();
    
    // Try immediate sync if online
    if (_isOnline) {
      _processSyncQueue();
    }
  }
  
  /// Process sync queue with 4G adaptive strategies
  Future<void> _processSyncQueue() async {
    if (!_isOnline || _syncQueue.isEmpty) return;
    
    final requestsToProcess = _syncQueue.take(_getBatchSize()).toList();
    
    for (final request in requestsToProcess) {
      if (!_isOnline) break;
      
      try {
        await _executeRequest(request);
        _syncQueue.remove(request);
        await _saveQueueToStorage();
      } catch (e) {
        print('Request failed: ${request.id} - $e');
        await _handleFailedRequest(request);
      }
      
      // Adaptive delay for 4G stability
      await Future.delayed(Duration(milliseconds: _getAdaptiveDelay()));
    }
  }
  
  /// Execute individual request with retry logic
  Future<void> _executeRequest(QueuedRequest request) async {
    try {
      final response = await _dio.request(
        request.endpoint,
        data: request.method == 'GET' ? null : request.data,
        options: Options(
          method: _getMethodFromString(request.method),
          headers: request.headers,
        ),
      );
      
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        print('Request successful: ${request.endpoint}');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('HTTP request failed: $e');
      rethrow;
    }
  }
  
  /// Get HTTP method from string
  String _getMethodFromString(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return 'POST';
      case 'PUT':
        return 'PUT';
      case 'DELETE':
        return 'DELETE';
      case 'GET':
      default:
        return 'GET';
    }
  }
  
  /// Handle failed request with retry logic
  Future<void> _handleFailedRequest(QueuedRequest request) async {
    request.retryCount++;
    
    // Exponential backoff for 4G stability
    final maxRetries = _getMaxRetries();
    if (request.retryCount <= maxRetries) {
      // Update last sync attempt time
      _lastSyncAttempts[request.id] = DateTime.now();
      
      // Calculate backoff delay
      final backoffDelay = _calculateBackoffDelay(request.retryCount);
      
      print('Retrying request ${request.id} in ${backoffDelay}ms (attempt ${request.retryCount}/$maxRetries)');
      
      // Schedule retry
      Timer(Duration(milliseconds: backoffDelay), () {
        if (_isOnline) {
          _processSyncQueue();
        }
      });
    } else {
      // Max retries reached - mark as failed
      print('Max retries reached for request ${request.id} - marking as failed');
      _syncQueue.remove(request);
      await _saveQueueToStorage();
    }
  }
  
  /// Compress data for 4G transmission
  Map<String, dynamic> _compressData(Map<String, dynamic> data) {
    // Remove null values and empty strings
    final compressed = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        // Truncate long strings for 4G efficiency
        if (entry.value is String && (entry.value as String).length > 1000) {
          compressed[entry.key] = (entry.value as String).substring(0, 1000);
        } else {
          compressed[entry.key] = entry.value;
        }
      }
    }
    
    return compressed;
  }
  
  /// Get batch size based on connection quality
  int _getBatchSize() {
    switch (_currentConnectivity) {
      case ConnectivityResult.wifi:
        return 10; // WiFi can handle larger batches
      case ConnectivityResult.mobile:
        return 3; // 4G LTE - smaller batches for stability
      case ConnectivityResult.ethernet:
        return 15; // Ethernet - largest batches
      default:
        return 1; // Unknown connection - smallest batches
    }
  }
  
  /// Get adaptive delay based on connection quality
  int _getAdaptiveDelay() {
    switch (_currentConnectivity) {
      case ConnectivityResult.wifi:
        return 100; // 100ms between requests
      case ConnectivityResult.mobile:
        return 500; // 500ms for 4G stability
      case ConnectivityResult.ethernet:
        return 50; // 50ms for wired connections
      default:
        return 1000; // 1s for unknown connections
    }
  }
  
  /// Get max retries based on connection quality
  int _getMaxRetries() {
    switch (_currentConnectivity) {
      case ConnectivityResult.wifi:
        return 3;
      case ConnectivityResult.mobile:
        return 5; // More retries for 4G
      case ConnectivityResult.ethernet:
        return 2;
      default:
        return 3;
    }
  }
  
  /// Calculate exponential backoff delay
  int _calculateBackoffDelay(int retryCount) {
    // Base delay: 1s, 2s, 4s, 8s, 16s for 4G
    final baseDelay = _currentConnectivity == ConnectivityResult.mobile ? 1000 : 500;
    return (baseDelay * (1 << (retryCount - 1))).clamp(1000, 30000);
  }
  
  /// Sort queue by priority and timestamp
  void _sortQueueByPriority() {
    _syncQueue.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority); // Higher priority first
      }
      return a.timestamp.compareTo(b.timestamp); // Older requests first
    });
  }
  
  /// Save queue to persistent storage
  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_syncQueue.map((r) => r.toJson()).toList());
      await prefs.setString('sync_queue', queueJson);
    } catch (e) {
      print('Error saving queue to storage: $e');
    }
  }
  
  /// Load queue from persistent storage
  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString('sync_queue');
      
      if (queueJson != null) {
        final List<dynamic> queueData = jsonDecode(queueJson);
        _syncQueue.clear();
        
        for (final item in queueData) {
          _syncQueue.add(QueuedRequest.fromJson(Map<String, dynamic>.from(item)));
        }
        
        _sortQueueByPriority();
        print('Loaded ${_syncQueue.length} queued requests from storage');
      }
    } catch (e) {
      print('Error loading queue from storage: $e');
    }
  }
  
  /// Get network statistics
  NetworkStats getNetworkStats() {
    return NetworkStats(
      isOnline: _isOnline,
      connectivityType: _currentConnectivity?.toString() ?? 'unknown',
      queuedRequests: _syncQueue.length,
      lastSyncAttempt: _lastSyncAttempts.isNotEmpty ? _lastSyncAttempts.values.last : null,
    );
  }
  
  /// Force sync all queued requests
  Future<void> forceSync() async {
    if (_isOnline) {
      await _processSyncQueue();
    } else {
      throw Exception('No network connection available');
    }
  }
  
  /// Clear sync queue
  Future<void> clearQueue() async {
    _syncQueue.clear();
    _lastSyncAttempts.clear();
    await _saveQueueToStorage();
  }
  
  /// Check if service is ready
  bool get isReady => _syncTimer != null;
  
  /// Get current connectivity status
  bool get isOnline => _isOnline;
  
  /// Get current connectivity type
  ConnectivityResult? get connectivityType => _currentConnectivity;
  
  /// Get queue size
  int get queueSize => _syncQueue.length;
  
  /// Cleanup resources
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _syncQueue.clear();
    _lastSyncAttempts.clear();
    _dio.close();
  }
}

// Data models for network optimization
class QueuedRequest {
  final String id;
  final String endpoint;
  final Map<String, dynamic> data;
  final String method;
  final Map<String, String>? headers;
  final int priority;
  final DateTime timestamp;
  int retryCount;
  
  QueuedRequest({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.method,
    this.headers,
    required this.priority,
    required this.timestamp,
    required this.retryCount,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'data': data,
      'method': method,
      'headers': headers,
      'priority': priority,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }
  
  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      id: json['id'],
      endpoint: json['endpoint'],
      data: Map<String, dynamic>.from(json['data']),
      method: json['method'],
      headers: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
      priority: json['priority'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      retryCount: json['retryCount'],
    );
  }
}

class NetworkStats {
  final bool isOnline;
  final String connectivityType;
  final int queuedRequests;
  final DateTime? lastSyncAttempt;
  
  NetworkStats({
    required this.isOnline,
    required this.connectivityType,
    required this.queuedRequests,
    this.lastSyncAttempt,
  });
}
