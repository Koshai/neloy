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
      print('🔐 Attempting sign in for: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Check if email is confirmed
        if (response.user!.emailConfirmedAt == null) {
          print('❌ Email not verified for: $email');
          throw 'Please verify your email address with the 6-digit code before signing in. Check your inbox for the verification code.';
        }
        
        print('✅ Sign in successful for: $email');
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Sign in error: $e');
      throw e;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      print('🚀 Attempting signup for: $email');
      
      // Create the account first with traditional signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      print('✅ Signup completed');
      print('   User: ${response.user?.email}');
      print('   Confirmed: ${response.user?.emailConfirmedAt != null}');
      
      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          print('📧 Sending verification code');
          
          // Send OTP for verification - try multiple methods
          try {
            // Method 1: Use resend to send OTP
            await _supabase.auth.resend(
              type: OtpType.signup,
              email: email,
            );
            print('✅ Verification code sent via resend');
          } catch (resendError) {
            print('⚠️ Resend failed, trying signInWithOtp: $resendError');
            
            // Method 2: Use signInWithOtp as backup (this will send OTP)
            await _supabase.auth.signInWithOtp(email: email);
            print('✅ Verification code sent via signInWithOtp');
          }
        } else {
          print('✅ User confirmed immediately');
          _isLoggedIn = true;
          notifyListeners();
        }
      } else {
        throw 'Failed to create account. Please try again.';
      }
    } catch (e) {
      print('❌ Signup error: $e');
      throw e;
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      print('📧 Resending verification code to: $email');
      
      // Try multiple methods to ensure OTP is sent
      try {
        // Method 1: Use resend for existing signup
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: email,
        );
        print('✅ Verification code sent via resend');
      } catch (resendError) {
        print('⚠️ Resend failed, trying signInWithOtp: $resendError');
        
        // Method 2: Use signInWithOtp as backup
        await _supabase.auth.signInWithOtp(email: email);
        print('✅ Verification code sent via signInWithOtp');
      }
    } catch (e) {
      print('❌ Failed to send verification code: $e');
      throw 'Failed to send verification code: ${e.toString()}';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      print('🔐 Sending password reset code to: $email');
      
      await _supabase.auth.resetPasswordForEmail(email);
      
      print('✅ Password reset code sent successfully');
    } catch (e) {
      print('❌ Failed to send password reset code: $e');
      throw 'Failed to send password reset code: ${e.toString()}';
    }
  }

  Future<void> verifyEmailWithOtp(String email, String otp) async {
    try {
      print('🔐 Verifying email with 6-digit code');
      print('   Email: $email');
      print('   Code: $otp');
      
      // Try different OTP types to handle various scenarios
      AuthResponse? response;
      
      try {
        // Method 1: Try as email verification (most common)
        response = await _supabase.auth.verifyOTP(
          type: OtpType.email,
          email: email,
          token: otp,
        );
        print('✅ Verified with email type');
      } catch (e1) {
        print('⚠️ Email type failed: $e1');
        
        try {
          // Method 2: Try as signup verification
          response = await _supabase.auth.verifyOTP(
            type: OtpType.signup,
            email: email,
            token: otp,
          );
          print('✅ Verified with signup type');
        } catch (e2) {
          print('⚠️ Signup type failed: $e2');
          
          try {
            // Method 3: Try as magic link
            response = await _supabase.auth.verifyOTP(
              type: OtpType.magiclink,
              email: email,
              token: otp,
            );
            print('✅ Verified with magiclink type');
          } catch (e3) {
            print('❌ All verification methods failed');
            throw 'Invalid verification code. Please check your 6-digit code and try again.';
          }
        }
      }
      
      if (response?.user != null && response?.session != null) {
        print('✅ Email verified and logged in successfully');
        _isLoggedIn = true;
        notifyListeners();
      } else {
        throw 'Verification failed. Please check your 6-digit code and try again.';
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      throw 'Invalid verification code. Please try again.';
    }
  }

  Future<void> verifyOtpAndUpdatePassword(String email, String otp, String newPassword) async {
    try {
      print('🔐 Resetting password with 6-digit code');
      
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: otp,
      );
      
      if (response.user != null && response.session != null) {
        print('✅ Code verified, updating password');
        
        final updateResponse = await _supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        
        if (updateResponse.user != null) {
          print('✅ Password updated successfully');
          await _supabase.auth.signOut();
        } else {
          throw 'Failed to update password';
        }
      } else {
        throw 'Invalid reset code. Please check your 6-digit code and try again.';
      }
    } catch (e) {
      print('❌ Password reset error: $e');
      throw 'Failed to reset password: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  bool get isEmailVerified {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  String? get currentUserEmail {
    return _supabase.auth.currentUser?.email;
  }
}