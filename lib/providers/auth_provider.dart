import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  bool _isLoggedIn = false;

  AuthProvider() {
    _isLoggedIn = _authService.isLoggedIn();
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _isLoggedIn = true;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
        notifyListeners();
      }
    });
  }

  bool get isLoggedIn => _isLoggedIn;

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Check if email is confirmed
        if (response.user!.emailConfirmedAt == null) {
          throw 'Please verify your email address before signing in. Check your inbox for a verification link.';
        }
        
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'ghor://email-verified', // Updated to use app deep link
      );
      
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        // User created but needs email verification
        throw 'Please check your email and click the verification link to complete your registration.';
      }
      
      // If email is already confirmed (shouldn't happen on first signup)
      if (response.user != null && response.user!.emailConfirmedAt != null) {
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'ghor://email-verified', // Updated to use app deep link
      );
    } catch (e) {
      throw 'Failed to resend verification email: ${e.toString()}';
    }
  }

  // Reset password - send email with reset link
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'ghor://reset-password', // Updated to use app deep link
      );
    } catch (e) {
      throw 'Failed to send password reset email: ${e.toString()}';
    }
  }

  // Update password with tokens from reset link
  Future<void> updatePassword(String newPassword, String? accessToken, String? refreshToken) async {
    try {
      if (accessToken != null && refreshToken != null) {
        // Alternative approach: recover session using the tokens
        try {
          await _supabase.auth.recoverSession(accessToken);
        } catch (e) {
          // If recoverSession doesn't work, try direct token approach
          print('Recover session failed, trying alternative approach: $e');
        }
      }
      
      // Update the password
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (response.user == null) {
        throw 'Failed to update password';
      }
      
      // Sign out after password update for security
      await _supabase.auth.signOut();
      
    } catch (e) {
      throw 'Failed to update password: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  // Check if user's email is verified
  bool get isEmailVerified {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  // Get current user email
  String? get currentUserEmail {
    return _supabase.auth.currentUser?.email;
  }
}