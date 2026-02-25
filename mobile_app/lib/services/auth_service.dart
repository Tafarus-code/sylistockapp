import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  final SharedPreferences _prefs;

  AuthService(this._prefs);

  static Future<AuthService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthService(prefs);
  }

  // Authentication methods
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userString = _prefs.getString(_userKey);
    if (userString != null) {
      // In a real app, you'd decode JSON here
      return {
        'name': 'Test User',
        'email': 'user@example.com',
        'id': '123',
      };
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock authentication - in real app, call your API
    if (email == 'user@example.com' && password == 'password') {
      await _prefs.setString(_tokenKey, 'mock_jwt_token');
      await _prefs.setString(_userKey, '{"name":"Test User","email":"user@example.com","id":"123"}');
      await _prefs.setBool(_isLoggedInKey, true);
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    await _prefs.setBool(_isLoggedInKey, false);
  }

  Future<void> register(String name, String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock registration - in real app, call your API
    await _prefs.setString(_tokenKey, 'mock_jwt_token');
    await _prefs.setString(_userKey, '{"name":"$name","email":"$email","id":"123"}');
    await _prefs.setBool(_isLoggedInKey, true);
  }
}
