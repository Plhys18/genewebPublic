import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utilities/api_service.dart';
import 'genes/gene_model.dart';

class UserAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BuildContext? _latestContext;

  void setContext(BuildContext context) {
    _latestContext = context;
  }

  // Check authentication state at startup
  Future<void> checkAuthState() async {
    // Check if we already have a valid token
    final isAuthed = ApiService().isAuthenticated;

    if (isAuthed) {
      try {
        // Fetch user profile to get username
        final userData = await ApiService().fetchUserProfile();
        _username = userData['username'] ?? '';
        _isLoggedIn = true;
        notifyListeners();
      } catch (e) {
        // Token might be invalid
        debugPrint('Error checking auth state: $e');
        await ApiService().logout();
        _isLoggedIn = false;
        notifyListeners();
      }
    }
  }

  // Improved login method that handles everything in one place
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService().login(username, password);

      if (success) {
        _username = username;
        _isLoggedIn = true;
        await _refreshDataAfterAuthChange();
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

  // Improved logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService().logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _username = '';
      _isLoggedIn = false;
      _isLoading = false;
      await _refreshDataAfterAuthChange();
      notifyListeners();
    }
  }

  // Centralized method to refresh data after auth changes
  Future<void> _refreshDataAfterAuthChange() async {
    if (_latestContext != null) {
      try {
        final geneModel = Provider.of<GeneModel>(_latestContext!, listen: false);

        // Clear existing data
        geneModel.removeEverythingAssociatedWithCurrentSession();

        // Reinitialize API service to update auth headers
        await ApiService.init();

        // Fetch organisms based on current auth state
        await _fetchOrganismsBasedOnAuth(geneModel);

        debugPrint('Data refreshed after auth state change');
      } catch (e) {
        debugPrint('Error during data refresh: $e');
      }
    }
  }

  // Fetch appropriate organisms based on authentication state
  Future<void> _fetchOrganismsBasedOnAuth(GeneModel geneModel) async {
    try {
      // Fetch public organisms for everyone
      await geneModel.fetchPublicOrganisms();

      // If logged in, fetch user-specific analysis history
      if (_isLoggedIn) {
        await geneModel.fetchUserAnalysesHistory().catchError((e) {
          debugPrint('Failed to fetch user analysis history: $e');
        });
      }
    } catch (e) {
      debugPrint('Error fetching organisms: $e');
    }
  }
}