import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _showOtpVerification = false;
  bool _showVerificationMessage = false;
  String _userEmail = '';

  @override
  Widget build(BuildContext context) {
    // Fixed register_screen.dart - Add proper scrolling
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      body: SafeArea( // Add SafeArea for better keyboard handling
        child: SingleChildScrollView( // Wrap entire body in SingleChildScrollView
          padding: EdgeInsets.all(16.0),
          child: ConstrainedBox( // Ensure minimum height for scrolling
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        kToolbarHeight - 32, // Account for AppBar and padding
            ),
            child: IntrinsicHeight( // Prevent Column from taking infinite height
              child: _buildCurrentScreen(),
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_showOtpVerification) return 'Verify Email';
    if (_showVerificationMessage) return 'Check Your Email';
    return 'Create Account';
  }

  Widget _buildCurrentScreen() {
    if (_showOtpVerification) {
      return _buildOtpVerificationScreen();
    } else if (_showVerificationMessage) {
      return _buildVerificationMessageScreen();
    } else {
      return _buildRegistrationForm();
    }
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome message
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.home_work,
                  size: 48,
                  color: Colors.blue[800],
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome to PropertyPro',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start managing your rental properties today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
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
          SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your password';
              }
              if (value!.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? CircularProgressIndicator()
                : Text('Create Account'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationMessageScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread,
                  size: 48,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Account Created Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'We\'ve sent a 6-digit verification code to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Enter the 6-digit code to verify your account and complete registration.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resendVerificationCode,
                icon: Icon(Icons.refresh),
                label: Text('Resend Code'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showOtpVerification = true;
                    _showVerificationMessage = false;
                  });
                },
                icon: Icon(Icons.pin),
                label: Text('Enter Code'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Back to Login'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        
        SizedBox(height: 24),
        
        // Troubleshooting
        ExpansionTile(
          title: Text(
            'Don\'t see the email?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Check your spam/junk folder'),
                  SizedBox(height: 4),
                  Text('• Make sure you entered the correct email address'),
                  SizedBox(height: 4),
                  Text('• Try resending the verification code'),
                  SizedBox(height: 4),
                  Text('• Wait a few minutes for the email to arrive'),
                  SizedBox(height: 4),
                  Text('• The code is valid for 10 minutes'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpVerificationScreen() {
    return Form(
      key: _otpFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.verified_user,
                  size: 48,
                  color: Colors.blue[800],
                ),
                SizedBox(height: 16),
                Text(
                  'Enter 6-Digit Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please enter the 6-digit verification code sent to your email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          
          TextFormField(
            controller: _otpController,
            decoration: InputDecoration(
              labelText: '6-Digit Verification Code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pin),
              hintText: '123456',
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 2,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter the 6-digit verification code';
              }
              if (value!.length != 6) {
                return 'Code must be 6 digits';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? CircularProgressIndicator()
                : Text('Verify Email'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          
          TextButton(
            onPressed: () {
              setState(() {
                _showOtpVerification = false;
                _showVerificationMessage = true;
              });
            },
            child: Text('Back to email instructions'),
          ),
          
          SizedBox(height: 8),
          
          TextButton(
            onPressed: _resendVerificationCode,
            child: Text('Resend verification code'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthProvider>().signUp(
          _emailController.text,
          _passwordController.text,
        );
        
        // Registration successful - show verification message
        setState(() {
          _userEmail = _emailController.text;
          _showVerificationMessage = true;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthProvider>().verifyEmailWithOtp(
          _userEmail,
          _otpController.text,
        );
        
        // Verification successful - navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } catch (e) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    try {
      await context.read<AuthProvider>().resendVerificationCode(_userEmail);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('6-digit verification code sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}