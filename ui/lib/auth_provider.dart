import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utilities/api_service.dart';
import 'genes/gene_model.dart';

class UserAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;

  BuildContext? _latestContext;

  void setContext(BuildContext context) {
    _latestContext = context;
  }

void logIn(String username) async {
  _username = username;
  _isLoggedIn = true;
  notifyListeners();
  
  await Future.delayed(const Duration(milliseconds: 300));
  await _forceCompleteReset();
}

void logOut() async {
  await ApiService().logout();
  _username = '';
  _isLoggedIn = false;
  notifyListeners();
  
  await Future.delayed(const Duration(milliseconds: 300));
  await _forceCompleteReset();
}

Future<void> _forceCompleteReset() async {
  if (_latestContext != null) {
    try {
      final geneModel = Provider.of<GeneModel>(_latestContext!, listen: false);
      final apiService = Provider.of<ApiService>(_latestContext!, listen: false);
      
      geneModel.removeEverythingAssociatedWithCurrentSession();
      
      await ApiService.init();
      
      await geneModel.fetchPublicOrganisms();
      
      if (_isLoggedIn) {
        await geneModel.fetchUserAnalysesHistory().catchError((e) {
          debugPrint('Failed to fetch user analysis history: $e');
        });
      }
      
      debugPrint('Complete data reset performed after auth state change');
    } catch (e) {
      debugPrint('Error during complete reset: $e');
    }
  }
}}
