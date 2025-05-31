import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  bool _showPasswordReset = false;
  String _userEmail = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: _buildCurrentScreen(),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_showPasswordReset) return 'Reset Password';
    if (_emailSent) return 'Check Your Email';
    return 'Forgot Password';
  }

  Widget _buildCurrentScreen() {
    if (_showPasswordReset) {
      return _buildPasswordResetForm();
    } else if (_emailSent) {
      return _buildEmailSentScreen();
    } else {
      return _buildEmailRequestForm();
    }
  }

  Widget _buildEmailRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Reset Your Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter your email address and we\'ll help you reset your password.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 32),

        // Email Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your email';
                  }
                  if (!value!.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
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
                            Text('Sending...'),
                          ],
                        )
                      : Text(
                          'Send Reset Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 32),
        
        // Back to Login
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back to Login',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSentScreen() {
    return Column(
      children: [
        // Success State
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: 60,
                  color: Colors.green[600],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'We\'ve sent password reset instructions to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _userEmail,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Follow the instructions in the email to reset your password. You can also use the code below if you received one.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              
              // Enter Code Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPasswordReset = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('I have a reset code'),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Resend Email Button
              OutlinedButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _emailSent = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Send Again',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Reset Your Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enter the reset code from your email and your new password.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),

          // Reset Code Field
          TextFormField(
            controller: _otpController,
            decoration: InputDecoration(
              labelText: 'Reset Code',
              hintText: 'Enter 6-digit code from email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.pin),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 2,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter the reset code';
              }
              if (value!.length != 6) {
                return 'Code must be 6 digits';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

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
            ),
            obscureText: true,
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
            ),
            obscureText: true,
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
                        Text('Resetting Password...'),
                      ],
                    )
                  : Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 20),

          // Back Button
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showPasswordReset = false;
                });
              },
              child: Text(
                'Back to email instructions',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().resetPassword(_emailController.text);

      setState(() {
        _userEmail = _emailController.text;
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reset email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use Supabase's verifyOTP for password reset
      await context.read<AuthProvider>().verifyOtpAndUpdatePassword(
        _userEmail,
        _otpController.text,
        _newPasswordController.text,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successfully! Please log in with your new password.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting password: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}