import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  bool _isLoggedIn = false;

  AuthProvider() {
    _isLoggedIn = _authService.isLoggedIn();
  }

  bool get isLoggedIn => _isLoggedIn;

  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email, password);
      // Auto-login after signup
      await signIn(email, password);
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }
}