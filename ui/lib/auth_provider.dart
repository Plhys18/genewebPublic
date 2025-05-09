import 'package:flutter/material.dart';
import 'utilities/api_service.dart';

class UserAuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => ApiService().isAuthenticated;
  String? get username => ApiService().username;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isValid = await ApiService().validateToken();

      if (!isValid) {
        await logout(silent: true);
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      await logout(silent: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService().login(username, password);

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid username or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      await ApiService().logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
