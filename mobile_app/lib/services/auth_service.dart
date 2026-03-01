import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _businessNameKey = 'auth_business_name';
  static const String _userIdKey = 'auth_user_id';
  static const String _merchantIdKey = 'auth_merchant_id';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.defaultHeaders,
  ));

  /// Get saved auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get saved user info
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey),
      'business_name': prefs.getString(_businessNameKey),
      'user_id': prefs.getString(_userIdKey),
      'merchant_id': prefs.getString(_merchantIdKey),
    };
  }

  /// Get the merchant ID (int) for API calls
  static Future<int?> getMerchantId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_merchantIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  /// Register a new user
  Future<AuthResult> register({
    required String username,
    required String password,
    required String businessName,
    String email = '',
    String location = '',
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.authRegister,
        data: {
          'username': username,
          'password': password,
          'business_name': businessName,
          'email': email,
          'location': location,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        await _saveAuthData(response.data);
        return AuthResult(
          success: true,
          token: response.data['token'],
          username: username,
          businessName: businessName,
        );
      }

      return AuthResult(
        success: false,
        error: response.data['error'] ?? 'Registration failed',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return AuthResult(
          success: false,
          error: 'Cannot connect to server at ${ApiConfig.baseUrl}. '
              'Make sure the Django server is running.',
        );
      }
      final errorMsg = e.response?.data?['error'] ??
          e.response?.data?['details']?.toString() ??
          'Server error: ${e.response?.statusCode ?? e.message}';
      return AuthResult(success: false, error: errorMsg);
    } catch (e) {
      return AuthResult(success: false, error: 'Registration failed: $e');
    }
  }

  /// Login with username and password
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.authLogin,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await _saveAuthData(response.data);
        return AuthResult(
          success: true,
          token: response.data['token'],
          username: response.data['user']?['username'] ?? username,
          businessName: response.data['user']?['business_name'] ?? '',
        );
      }

      return AuthResult(
        success: false,
        error: response.data['error'] ?? 'Login failed',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return AuthResult(
          success: false,
          error: 'Cannot connect to server at ${ApiConfig.baseUrl}. '
              'Make sure the Django server is running.',
        );
      }
      final errorMsg =
          e.response?.data?['error'] ?? 'Server error: ${e.response?.statusCode ?? e.message}';
      return AuthResult(success: false, error: errorMsg);
    } catch (e) {
      return AuthResult(success: false, error: 'Login failed: $e');
    }
  }

  /// Logout and clear saved data
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        _dio.options.headers['Authorization'] = 'Token $token';
        await _dio.post(ApiConfig.authLogout);
      } catch (_) {
        // Ignore errors — clear local data anyway
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_businessNameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_merchantIdKey);
  }

  /// Get current user profile from server
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      _dio.options.headers['Authorization'] = 'Token $token';
      final response = await _dio.get(ApiConfig.authProfile);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString(_tokenKey, data['token']);
    }
    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) {
      await prefs.setString(_usernameKey, user['username'] ?? '');
      await prefs.setString(
          _businessNameKey, user['business_name'] ?? '');
      await prefs.setString(_userIdKey, user['id']?.toString() ?? '');
      if (user['merchant_id'] != null) {
        await prefs.setString(
            _merchantIdKey, user['merchant_id'].toString());
      }
    }
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final String? username;
  final String? businessName;
  final String? error;

  AuthResult({
    required this.success,
    this.token,
    this.username,
    this.businessName,
    this.error,
  });
}

