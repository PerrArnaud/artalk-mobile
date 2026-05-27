import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authService.isAuthenticated();
      
      if (_isAuthenticated) {
        _user = await _authService.getStoredUser();
        
        // Verify token is still valid by fetching current user
        final response = await _authService.getCurrentUser();
        if (response.success && response.data != null) {
          _user = response.data;
        } else {
          // Token invalid, clear auth
          _isAuthenticated = false;
          _user = null;
          await _authService.logout();
        }
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email: email, password: password);
      
      if (response.success) {
        _isAuthenticated = true;
        _user = await _authService.getStoredUser();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      
      if (response.success && response.data != null) {
        _isAuthenticated = true;
        _user = await _authService.getStoredUser();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final response = await _authService.getCurrentUser();
      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
      }
    } catch (_) {
      // Ignore refresh errors silently
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
