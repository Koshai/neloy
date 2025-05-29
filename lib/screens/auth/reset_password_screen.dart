import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;

  const ResetPasswordScreen({
    Key? key,
    this.accessToken,
    this.refreshToken,
  }) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _handlePasswordResetSession();
  }

  Future<void> _handlePasswordResetSession() async {
    try {
      // If we have tokens from the deep link, validate them
      if (widget.accessToken != null && widget.refreshToken != null) {
        // For password reset, we don't always need to set the full session
        // The tokens will be used directly in the password update call
        print('Password reset tokens received');
        
        // Optional: Validate the token by trying to get user info
        try {
          final user = await Supabase.instance.client.auth.getUser(widget.accessToken!);
          if (user.user != null) {
            print('Valid reset token for user: ${user.user!.email}');
            return; // Token is valid, proceed with password reset
          }
        } catch (tokenError) {
          print('Token validation error: $tokenError');
        }
        
        // If token validation fails, we can still try the password reset
        // as the updateUser method will validate the token itself
      } else {
        print('No reset tokens provided');
        _showErrorDialog('Invalid reset link. Please request a new password reset.');
      }
    } catch (e) {
      print('Error handling reset session: $e');
      _showErrorDialog('Invalid or expired reset link. Please request a new password reset.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create New Password',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter your new password below. Make sure it\'s strong and secure.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),

            // Password Reset Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // New Password Field
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter your new password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureNewPassword,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a new password';
                      }
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your new password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Password Requirements
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildRequirement('At least 6 characters long'),
                        _buildRequirement('Contains letters and numbers (recommended)'),
                        _buildRequirement('Avoid common passwords'),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Reset Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Updating Password...'),
                              ],
                            )
                          : Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Back to Login
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if we have a current session
      final currentSession = Supabase.instance.client.auth.currentSession;
      
      if (currentSession == null && widget.accessToken != null) {
        // Try to recover session one more time before password update
        try {
          await Supabase.instance.client.auth.recoverSession(widget.accessToken!);
          print('Session recovered before password update');
        } catch (e) {
          print('Failed to recover session: $e');
          // Continue anyway - sometimes the updateUser works without explicit session
        }
      }

      // Attempt password update
      UserResponse response;
      
      try {
        // Standard method
        response = await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );
      } catch (sessionError) {
        if (widget.accessToken != null) {
          // Alternative: Try again after ensuring session
          final client = Supabase.instance.client.auth;
          
          // Try with recovered session
          response = await client.updateUser(
            UserAttributes(password: _newPasswordController.text),
          );
        } else {
          rethrow;
        }
      }

      if (response.user != null) {
        print('Password updated successfully for user: ${response.user!.email}');
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to update password. Please try again.');
      }
    } on AuthException catch (authError) {
      print('Auth error during password reset: ${authError.message}');
      
      if (authError.message.contains('session') || authError.message.contains('missing')) {
        _showErrorDialog('Your reset link has expired. Please request a new password reset.');
      } else if (authError.message.contains('weak') || authError.message.contains('password')) {
        _showErrorDialog('Password is too weak. Please choose a stronger password.');
      } else {
        _showErrorDialog('Authentication error: ${authError.message}');
      }
    } catch (e) {
      print('Password reset error: $e');
      
      // For session missing errors, try alternative approach
      if (e.toString().contains('session') || e.toString().contains('missing')) {
        if (widget.accessToken != null) {
          try {
            // Direct API approach as last resort
            await _updatePasswordDirect();
            return;
          } catch (directError) {
            print('Direct API approach failed: $directError');
          }
        }
        _showErrorDialog('Your reset link has expired or is invalid. Please request a new password reset.');
      } else if (e.toString().contains('expired')) {
        _showErrorDialog('Your reset link has expired. Please request a new password reset.');
      } else {
        _showErrorDialog('Error updating password: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Direct API call as fallback
  Future<void> _updatePasswordDirect() async {
    final url = Uri.parse('https://enxmmalzlpmjphitonyx.supabase.co/auth/v1/user');
    
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.accessToken!}',
        'Content-Type': 'application/json',
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVueG1tYWx6bHBtanBoaXRvbnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNjU5NzYsImV4cCI6MjA2MTk0MTk3Nn0.DPhJmPz67GNWjtv0m6t_tfo7rhgHFUym1vB75rTdvOY',
      },
      body: jsonEncode({
        'password': _newPasswordController.text,
      }),
    );
    
    if (response.statusCode == 200) {
      print('Password updated via direct API');
      _showSuccessDialog();
    } else {
      throw 'Direct API error: ${response.statusCode} - ${response.body}';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Password Updated'),
          ],
        ),
        content: Text(
          'Your password has been successfully updated. You can now log in with your new password.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}