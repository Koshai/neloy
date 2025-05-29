import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<User?> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://yourapp.com/email-verified',
      );
      return response.user;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'https://yourapp.com/email-verified',
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://yourapp.com/reset-password',
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (response.user == null) {
        throw 'Failed to update password';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  bool isLoggedIn() {
    final user = _supabase.auth.currentUser;
    return user != null && user.emailConfirmedAt != null;
  }

  bool isEmailVerified() {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }
}