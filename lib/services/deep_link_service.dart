import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/email_verified_screen.dart';

class DeepLinkService {
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;
  static AppLinks? _appLinks;
  
  static void initialize(BuildContext context) {
    _context = context;
    _appLinks = AppLinks();
    _handleInitialLink();
    _handleIncomingLinks();
  }
  
  static void dispose() {
    _linkSubscription?.cancel();
  }
  
  // Handle the initial link when the app is opened from a deep link
  static Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks?.getInitialAppLink();
      if (initialUri != null) {
        print('Initial deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Error handling initial link: $e');
    }
  }
  
  // Handle incoming links when the app is already running
  static void _handleIncomingLinks() {
    _linkSubscription = _appLinks?.uriLinkStream.listen(
      (Uri uri) {
        print('Incoming deep link: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }
  
  static void _handleDeepLink(Uri uri) {
    if (_context == null) {
      print('Context not available for deep link handling');
      return;
    }
    
    final path = uri.path;
    final scheme = uri.scheme;
    
    print('Handling deep link - Scheme: $scheme, Path: $path');
    print('Full URI: ${uri.toString()}');
    print('Query parameters: ${uri.queryParameters}');
    print('Fragment: ${uri.fragment}');
    
    // Handle password reset
    if ((path.contains('reset-password') || uri.toString().contains('reset-password'))) {
      print('Password reset link detected');
      
      // Extract tokens from URL
      String? accessToken;
      String? refreshToken;
      
      // Try query parameters first
      accessToken = uri.queryParameters['access_token'];
      refreshToken = uri.queryParameters['refresh_token'];
      
      // If not in query parameters, try fragment
      if (accessToken == null && uri.fragment.isNotEmpty) {
        final fragmentUri = Uri.parse('?${uri.fragment}');
        accessToken = fragmentUri.queryParameters['access_token'];
        refreshToken = fragmentUri.queryParameters['refresh_token'];
      }
      
      print('Extracted tokens - Access: ${accessToken != null}, Refresh: ${refreshToken != null}');
      
      // Navigate to reset password screen
      Navigator.of(_context!).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ),
        (route) => false, // Remove all previous routes
      );
      return;
    }
    
    // Handle email verification
    if ((path.contains('email-verified') || uri.toString().contains('email-verified') || 
         path.contains('confirm') || uri.toString().contains('confirm'))) {
      print('Email verification link detected');
      
      // Check for errors first
      String? error = uri.queryParameters['error'];
      String? errorCode = uri.queryParameters['error_code'];
      String? errorDescription = uri.queryParameters['error_description'];
      
      // Also check fragment for errors
      if (error == null && uri.fragment.isNotEmpty) {
        final fragmentUri = Uri.parse('?${uri.fragment}');
        error = fragmentUri.queryParameters['error'];
        errorCode = fragmentUri.queryParameters['error_code'];
        errorDescription = fragmentUri.queryParameters['error_description'];
      }
      
      if (error != null) {
        print('Email verification error detected:');
        print('- Error: $error');
        print('- Error Code: $errorCode');
        print('- Description: $errorDescription');
        
        // Navigate to email verified screen with error info
        Navigator.of(_context!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailVerifiedScreen(
              accessToken: null,
              refreshToken: null,
              error: error,
              errorCode: errorCode,
              errorDescription: errorDescription,
            ),
          ),
          (route) => false,
        );
        return;
      }
      
      // Extract tokens and verification codes
      String? accessToken;
      String? refreshToken;
      String? tokenHash;
      String? type;
      String? code; // Add this for OTP verification
      
      // Try query parameters first
      accessToken = uri.queryParameters['access_token'];
      refreshToken = uri.queryParameters['refresh_token'];
      tokenHash = uri.queryParameters['token_hash'];
      type = uri.queryParameters['type'];
      code = uri.queryParameters['code']; // Extract verification code
      
      // If not in query parameters, try fragment
      if (accessToken == null && uri.fragment.isNotEmpty) {
        final fragmentUri = Uri.parse('?${uri.fragment}');
        accessToken = fragmentUri.queryParameters['access_token'];
        refreshToken = fragmentUri.queryParameters['refresh_token'];
        tokenHash = fragmentUri.queryParameters['token_hash'];
        type = fragmentUri.queryParameters['type'];
        code = fragmentUri.queryParameters['code'];
      }
      
      print('Email verification tokens:');
      print('- Access token: ${accessToken != null ? "Present (${accessToken!.length} chars)" : "Missing"}');
      print('- Refresh token: ${refreshToken != null ? "Present (${refreshToken!.length} chars)" : "Missing"}');
      print('- Token hash: ${tokenHash != null ? "Present" : "Missing"}');
      print('- Verification code: ${code != null ? "Present (${code!.length} chars)" : "Missing"}');
      print('- Type: $type');
      
      // Navigate to email verified screen
      Navigator.of(_context!).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => EmailVerifiedScreen(
            accessToken: accessToken,
            refreshToken: refreshToken,
            verificationCode: code, // Pass the verification code
          ),
        ),
        (route) => false, // Remove all previous routes
      );
      return;
    }
    
    // Handle billing return (existing functionality)
    if (path.contains('billing-return') || uri.toString().contains('billing-return')) {
      print('Billing return link detected');
      // Handle billing return - you can add specific logic here
      // For now, just print
      print('Billing return handled');
      return;
    }
    
    print('Unhandled deep link: ${uri.toString()}');
  }
}