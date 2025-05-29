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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showVerificationMessage = false;
  String _userEmail = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showVerificationMessage ? 'Verify Your Email' : 'Create Account'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _showVerificationMessage ? _buildVerificationScreen() : _buildRegistrationForm(),
      ),
    );
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

  Widget _buildVerificationScreen() {
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
                'We\'ve sent a verification email to:',
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
                'Please check your email and click the verification link to activate your account.',
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
        
        // Instructions card
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[800]),
                    SizedBox(width: 8),
                    Text(
                      'Next Steps:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildInstructionStep(
                  '1.',
                  'Check your email inbox',
                  'Look for an email from PropertyPro',
                  Icons.inbox,
                ),
                _buildInstructionStep(
                  '2.',
                  'Click the verification link',
                  'This will activate your account',
                  Icons.link,
                ),
                _buildInstructionStep(
                  '3.',
                  'Return to the app',
                  'Log in with your credentials',
                  Icons.login,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resendVerificationEmail,
                icon: Icon(Icons.refresh),
                label: Text('Resend Email'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Back to Login'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
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
                  Text('• Try resending the verification email'),
                  SizedBox(height: 4),
                  Text('• Wait a few minutes for the email to arrive'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String step, String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Icon(icon, color: Colors.blue[600], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
        
        // If we reach here, registration was successful but email needs verification
        setState(() {
          _userEmail = _emailController.text;
          _showVerificationMessage = true;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        
        // Check if the error is about email confirmation
        if (e.toString().toLowerCase().contains('email') && 
            e.toString().toLowerCase().contains('confirm')) {
          setState(() {
            _userEmail = _emailController.text;
            _showVerificationMessage = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      // Call Supabase to resend verification email
      await context.read<AuthProvider>().resendVerificationEmail(_userEmail);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}