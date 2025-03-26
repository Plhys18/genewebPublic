import 'package:flutter/material.dart';

class UserAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';
  bool get isLoggedIn => _isLoggedIn;

  get getUsername => _username;

  void logIn(String username) {
    _username = username;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logOut() {
    _username = '';
    _isLoggedIn = false;
    notifyListeners();
  }
}
