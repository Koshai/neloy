import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class EmailVerifiedScreen extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;
  final String? verificationCode; // Add this
  final String? error;
  final String? errorCode;
  final String? errorDescription;

  const EmailVerifiedScreen({
    Key? key,
    this.accessToken,
    this.refreshToken,
    this.verificationCode, // Add this
    this.error,
    this.errorCode,
    this.errorDescription,
  }) : super(key: key);

  @override
  _EmailVerifiedScreenState createState() => _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends State<EmailVerifiedScreen> {
  bool _isLoading = true;
  bool _verificationSuccess = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _handleEmailVerification();
  }

  Future<void> _handleEmailVerification() async {
    try {
      // Check if there's an error in the URL first
      if (widget.error != null) {
        print('Email verification error: ${widget.error}');
        print('Error code: ${widget.errorCode}');
        print('Error description: ${widget.errorDescription}');
        
        String errorMessage;
        switch (widget.errorCode) {
          case 'otp_expired':
            errorMessage = 'Your email verification link has expired. Please request a new verification email.';
            break;
          case 'access_denied':
            errorMessage = 'Access denied. The verification link may have been used already or is invalid.';
            break;
          case 'invalid_request':
            errorMessage = 'Invalid verification request. Please try signing up again.';
            break;
          default:
            errorMessage = widget.errorDescription?.replaceAll('+', ' ') ?? 'Email verification failed. Please try again.';
        }
        
        setState(() {
          _verificationSuccess = false;
          _message = errorMessage;
        });
        return;
      }
      
      // Proceed with normal verification if no error
      if (widget.verificationCode != null) {
        // Handle OTP verification with code
        print('Email verification code received: ${widget.verificationCode}');
        
        try {
          // Use verifyOtp to confirm the email with the code
          final response = await Supabase.instance.client.auth.verifyOTP(
            type: OtpType.signup,
            token: widget.verificationCode!,
          );
          
          if (response.user != null && response.session != null) {
            print('Email verified successfully with OTP');
            print('User email: ${response.user!.email}');
            print('Email confirmed: ${response.user!.emailConfirmedAt != null}');
            
            setState(() {
              _verificationSuccess = true;
              _message = 'Email verified successfully! Welcome to PropertyPro.';
            });
            return;
          } else {
            throw 'OTP verification failed - no user or session returned';
          }
        } catch (otpError) {
          print('OTP verification failed: $otpError');
          
          // Try alternative verification methods
          setState(() {
            _verificationSuccess = false;
            _message = 'Email verification failed. The verification code may have expired or been used already.';
          });
          return;
        }
      }
      else if (widget.accessToken != null && widget.refreshToken != null) {
        // Handle token-based verification (existing logic)
        print('Email verification tokens received');
        print('Access token length: ${widget.accessToken!.length}');
        print('Refresh token length: ${widget.refreshToken!.length}');
        
        // Try to set/recover the session with the verification tokens
        try {
          // Method 1: Try to recover session
          final sessionResponse = await Supabase.instance.client.auth.recoverSession(widget.accessToken!);
          
          if (sessionResponse.session != null && sessionResponse.user != null) {
            print('Session recovered successfully');
            print('User email: ${sessionResponse.user!.email}');
            print('Email confirmed: ${sessionResponse.user!.emailConfirmedAt != null}');
            
            setState(() {
              _verificationSuccess = true;
              _message = 'Email verified successfully! Welcome to PropertyPro.';
            });
            return;
          }
        } catch (recoverError) {
          print('Session recovery failed: $recoverError');
          
          // Method 2: Try to verify the token by getting user info
          try {
            final userResponse = await Supabase.instance.client.auth.getUser(widget.accessToken!);
            
            if (userResponse.user != null) {
              print('User retrieved successfully');
              print('User email: ${userResponse.user!.email}');
              print('Email confirmed: ${userResponse.user!.emailConfirmedAt != null}');
              
              // Check if email is confirmed
              if (userResponse.user!.emailConfirmedAt != null) {
                setState(() {
                  _verificationSuccess = true;
                  _message = 'Email verified successfully! You can now access all features.';
                });
              } else {
                // Email might still be in the process of being confirmed
                setState(() {
                  _verificationSuccess = true;
                  _message = 'Email verification in progress. You can now log in to your account.';
                });
              }
              return;
            }
          } catch (getUserError) {
            print('Get user failed: $getUserError');
          }
        }
        
        // Method 3: Try direct API verification
        try {
          await _verifyEmailDirect();
          return;
        } catch (directError) {
          print('Direct verification failed: $directError');
        }
        
        // If all methods fail
        setState(() {
          _verificationSuccess = false;
          _message = 'Email verification failed. The verification link may have expired or been used already.';
        });
        
      } else {
        print('No verification tokens or code provided');
        print('Access token present: ${widget.accessToken != null}');
        print('Refresh token present: ${widget.refreshToken != null}');
        print('Verification code present: ${widget.verificationCode != null}');
        
        setState(() {
          _verificationSuccess = false;
          _message = 'Invalid verification link. Please request a new verification email.';
        });
      }
    } catch (e) {
      print('Email verification error: $e');
      setState(() {
        _verificationSuccess = false;
        _message = 'An error occurred during verification: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Direct API verification with verification code
  Future<void> _verifyWithCodeDirect() async {
    if (widget.verificationCode == null) {
      throw 'No verification code available';
    }
    
    print('Attempting direct verification with code');
    
    // Try to confirm the signup using the verification code
    final url = Uri.parse('https://enxmmalzlpmjphitonyx.supabase.co/auth/v1/verify');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVueG1tYWx6bHBtanBoaXRvbnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNjU5NzYsImV4cCI6MjA2MTk0MTk3Nn0.DPhJmPz67GNWjtv0m6t_tfo7rhgHFUym1vB75rTdvOY',
      },
      body: jsonEncode({
        'type': 'signup',
        'token': widget.verificationCode!,
      }),
    );
    
    print('Direct code verification response: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['user'] != null) {
        print('Direct code verification successful');
        
        // Set the session if we get access and refresh tokens
        if (data['access_token'] != null && data['refresh_token'] != null) {
          try {
            await Supabase.instance.client.auth.recoverSession(data['access_token']);
            print('Session established after verification');
          } catch (sessionError) {
            print('Session establishment failed: $sessionError');
            // Continue anyway, verification was successful
          }
        }
        
        setState(() {
          _verificationSuccess = true;
          _message = 'Email verified successfully! You can now log in to your account.';
        });
      } else {
        throw 'Invalid response from verification API';
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['msg'] ?? errorData['message'] ?? 'Unknown error';
      throw 'Direct verification failed: $errorMsg';
    }
  }

  // Direct API verification as fallback for token-based verification
  Future<void> _verifyEmailDirect() async {
    if (widget.accessToken == null) {
      throw 'No access token available';
    }
    
    // Try to confirm the email using the token
    final url = Uri.parse('https://enxmmalzlpmjphitonyx.supabase.co/auth/v1/verify');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.accessToken!}',
        'Content-Type': 'application/json',
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVueG1tYWx6bHBtanBoaXRvbnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNjU5NzYsImV4cCI6MjA2MTk0MTk3Nn0.DPhJmPz67GNWjtv0m6t_tfo7rhgHFUym1vB75rTdvOY',
      },
      body: jsonEncode({
        'type': 'signup',
        'token': widget.accessToken!,
      }),
    );
    
    print('Direct token verification response: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['user'] != null) {
        print('Direct token verification successful');
        setState(() {
          _verificationSuccess = true;
          _message = 'Email verified successfully via direct API!';
        });
      } else {
        throw 'Invalid response from verification API';
      }
    } else {
      throw 'Direct token verification failed: ${response.statusCode}';
    }
  }

  void _showEmailInputDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Email Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter your email address to resend the verification link.'),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                try {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  await Supabase.instance.client.auth.resend(
                    type: OtpType.signup,
                    email: email,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New verification email sent to $email!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid email address')),
                );
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                // Loading state
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Verifying your email...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                // Verification result
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _verificationSuccess ? Colors.green[50] : Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _verificationSuccess ? Icons.check_circle : Icons.error,
                    size: 60,
                    color: _verificationSuccess ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                SizedBox(height: 32),
                
                Text(
                  _verificationSuccess ? 'Email Verified!' : 'Verification Failed',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                SizedBox(height: 16),
                
                Text(
                  _message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                
                // Action buttons
                if (_verificationSuccess) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => DashboardScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue to Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      // Resend verification email
                      try {
                        // Show loading
                        setState(() => _isLoading = true);
                        
                        // Get the current user's email if available
                        final currentUser = Supabase.instance.client.auth.currentUser;
                        
                        if (currentUser?.email != null) {
                          await Supabase.instance.client.auth.resend(
                            type: OtpType.signup,
                            email: currentUser!.email!,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('New verification email sent to ${currentUser.email}!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // If no current user, ask for email
                          _showEmailInputDialog();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error sending email: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                    child: Text(
                      widget.errorCode == 'otp_expired' 
                          ? 'Send New Verification Email'
                          : 'Resend Verification Email'
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}