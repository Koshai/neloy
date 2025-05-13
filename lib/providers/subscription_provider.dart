import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _plan = 'free'; // 'free', 'basic', 'premium'
  DateTime? _subscriptionExpiryDate;
  bool _showAnnualPlans = false;
  
  // Add Stripe-related properties
  String? _stripeCustomerId;
  String? _stripeSubscriptionId;
  String? _subscriptionStatus;
  DateTime? _currentPeriodStart;
  DateTime? _currentPeriodEnd;
  bool _cancelAtPeriodEnd = false;
  DateTime? _lastPaymentDate;
  double? _lastPaymentAmount;
  String? _lastPaymentError;
  
  // Freemium limits
  final int _freePropertyLimit = 1;
  final int _freeTenantLimit = 5;
  final int _freeDocumentLimit = 5;
  
  // Current usage
  int _propertyCount = 0;
  int _tenantCount = 0;
  int _documentCount = 0;

  // Existing getters
  bool get isLoading => _isLoading;
  String get plan => _plan;
  bool get isPremium => _plan != 'free';
  bool get showAnnualPlans => _showAnnualPlans;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;
  
  // Add getters for Stripe properties
  String? get stripeCustomerId => _stripeCustomerId;
  String? get stripeSubscriptionId => _stripeSubscriptionId;
  String? get subscriptionStatus => _subscriptionStatus;
  bool get cancelAtPeriodEnd => _cancelAtPeriodEnd;
  String? get lastPaymentError => _lastPaymentError;
  DateTime? get lastPaymentDate => _lastPaymentDate;
  
  // Existing property limit getters
  int get propertyLimit => isPremium ? 999 : _freePropertyLimit;
  int get tenantLimit => isPremium ? 999 : _freeTenantLimit;
  int get documentLimit => isPremium ? 999 : _freeDocumentLimit;
  
  // Existing usage getters
  int get propertyCount => _propertyCount;
  int get tenantCount => _tenantCount;
  int get documentCount => _documentCount;
  
  // Existing limit checkers
  int get remainingProperties => propertyLimit - _propertyCount;
  int get remainingTenants => tenantLimit - _tenantCount;
  int get remainingDocuments => documentLimit - _documentCount;
  
  bool get canAddProperty => isPremium || _propertyCount < _freePropertyLimit;
  bool get canAddTenant => isPremium || _tenantCount < _freeTenantLimit;
  bool get canAddDocument => isPremium || _documentCount < _freeDocumentLimit;

  SubscriptionProvider() {
    loadSubscriptionStatus();
  }

  // Update this method to load Stripe subscription data too
  Future<void> loadSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check if user has subscription info
      final response = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        // Load Stripe properties
        _stripeCustomerId = response['stripe_customer_id'];
        _stripeSubscriptionId = response['stripe_subscription_id'];
        _subscriptionStatus = response['subscription_status'];
        _cancelAtPeriodEnd = response['cancel_at_period_end'] ?? false;
        _lastPaymentError = response['last_payment_error'];
        
        if (response['current_period_start'] != null) {
          _currentPeriodStart = DateTime.parse(response['current_period_start']);
        }
        
        if (response['current_period_end'] != null) {
          _currentPeriodEnd = DateTime.parse(response['current_period_end']);
        }
        
        if (response['last_payment_date'] != null) {
          _lastPaymentDate = DateTime.parse(response['last_payment_date']);
        }
        
        _lastPaymentAmount = response['last_payment_amount'];

        // Check if has active subscription
        final subscriptionEndStr = response['subscription_end_date'];
        if (subscriptionEndStr != null) {
          _subscriptionExpiryDate = DateTime.parse(subscriptionEndStr);
          final isActive = 
              response['is_active'] == true && 
              _subscriptionExpiryDate!.isAfter(DateTime.now());
          
          if (isActive) {
            _plan = response['subscription_plan'] ?? 'free';
          } else {
            _plan = 'free';
          }
        }
      }
      
      // Load current usage
      await loadUsageCounts();
      
    } catch (e) {
      print('Error loading subscription: $e');
      _plan = 'free';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Keep your existing loadUsageCounts method
  Future<void> loadUsageCounts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Get property count
      final properties = await _supabase
          .from('properties')
          .select('id')
          .eq('user_id', user.id);
      _propertyCount = properties.length;
      
      // Get tenant count
      final tenants = await _supabase
          .from('tenants')
          .select('id')
          .eq('user_id', user.id);
      _tenantCount = tenants.length;
      
      // Get document count
      final documents = await _supabase
          .from('documents')
          .select('id')
          .eq('user_id', user.id);
      _documentCount = documents.length;
      
    } catch (e) {
      print('Error loading usage counts: $e');
    }
  }

  void togglePlanType() {
    _showAnnualPlans = !_showAnnualPlans;
    notifyListeners();
  }

  // Update the subscribe method to use Stripe
  Future<void> subscribe(BuildContext context, String planId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';
      if (user.email == null) throw 'User email is required for subscription';

      // First, check if the user already has an active subscription
      try {
        final response = await _supabase
            .from('user_subscriptions')
            .select()
            .eq('user_id', user.id)
            .eq('is_active', true)
            .maybeSingle();
        
        if (response != null && response['is_active'] == true) {
          // User already has an active subscription
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You already have an active subscription. Please manage it in the billing portal.')),
          );
          return; // Exit the method
        }
      } catch (e) {
        print('Error checking existing subscription: $e');
        // Continue with subscription creation anyway
      }
      
      // Optional: Get auth token if using JWT verification
      String? authHeader;
      try {
        final token = await _getAuthToken();
        if (token != null) {
          authHeader = 'Bearer $token';
        }
      } catch (e) {
        print('Warning: Could not get auth token: $e');
        // Continue without token if JWT is not enforced
      }

      print('Creating customer with userId: ${user.id}, email: ${user.email}');
      
      // 1. Get or create a Stripe customer for this user
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Only add Authorization header if we have a token
      if (authHeader != null) {
        headers['Authorization'] = authHeader;
      }
      
      final customerResponse = await http.post(
        Uri.parse('${AppConstants.backendUrl}/get-or-create-customer'),
        headers: headers,
        body: json.encode({
          'userId': user.id,
          'email': user.email,
        }),
      );
      
      if (customerResponse.statusCode != 200) {
        final responseBody = customerResponse.body;
        final errorMessage = responseBody.isNotEmpty 
            ? json.decode(responseBody)['error'] ?? 'Failed to create customer'
            : 'Failed to create customer';
        throw errorMessage;
      }
      
      final responseData = json.decode(customerResponse.body);
      final customerId = responseData['customerId'];
      
      if (customerId == null) {
        throw 'Failed to get customer ID from server';
      }

      print('Customer response status: ${customerResponse.statusCode}');
      print('Customer response body: ${customerResponse.body}');
      
      // 2. Map planId to Stripe priceId
      final priceId = _getPriceIdForPlan(planId);
      
      // 3. Create a Stripe subscription
      print('Creating subscription with customerId: $customerId, priceId: $priceId');
      
      // Use the same headers as the customer request
      final subscriptionResponse = await http.post(
        Uri.parse('${AppConstants.backendUrl}/stripe-create-subscription'),
        headers: headers,
        body: json.encode({
          'customerId': customerId,
          'priceId': priceId,
          'userId': user.id,
        }),
      );
      
      if (subscriptionResponse.statusCode != 200) {
        final responseBody = subscriptionResponse.body;
        final errorMessage = responseBody.isNotEmpty 
            ? json.decode(responseBody)['error'] ?? 'Failed to create subscription'
            : 'Failed to create subscription';
        throw errorMessage;
      }
      
      final subResponseData = json.decode(subscriptionResponse.body);
      final clientSecret = subResponseData['clientSecret'];
      final subscriptionId = subResponseData['subscriptionId'];
      
      if (clientSecret == null) {
        throw 'Failed to get client secret from server';
      }

      print('Subscription response status: ${subscriptionResponse.statusCode}');
      print('Subscription response body: ${subscriptionResponse.body}');
      print('Client secret received: ${clientSecret.substring(0, 10)}...'); // Never log the full secret
      
      // 4. IMPORTANT CHANGE: Use Payment Sheet instead of direct confirmation
      print('Initializing payment sheet...');
      try {
        // Initialize the payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Property Management App',
            customerId: customerId,
            style: ThemeMode.system,
          ),
        );
        print('Payment sheet initialized successfully');
        
        // Present the payment sheet to collect payment details
        print('Presenting payment sheet...');
        await Stripe.instance.presentPaymentSheet();
        print('Payment sheet presented and completed successfully');
        
        // If we get here, the payment was successful (exceptions are thrown otherwise)
        _plan = 'premium';
        _subscriptionExpiryDate = DateTime.now().add(Duration(days: 30));
        _stripeSubscriptionId = subscriptionId;
        _stripeCustomerId = customerId;

        // FALLBACK: Manual update to database
        try {
          print('Manually updating subscription status in database');
          await _supabase.from('user_subscriptions').upsert({
            'user_id': user.id,
            'stripe_customer_id': customerId,
            'stripe_subscription_id': subscriptionId,
            'subscription_plan': 'premium',
            'is_active': true,
            'subscription_status': 'active',
            'subscription_end_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('Manual update successful');
        } catch (dbError) {
          print('Error manually updating database: $dbError');
        }
        
        // Refresh subscription data
        await loadSubscriptionStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription activated successfully!')),
        );
      } catch (e) {
        print('Stripe error: $e');
        
        // Check if user canceled the payment
        if (e is StripeException && e.error.code == FailureCode.Canceled) {
          print('Payment canceled by user');
        } else {
          // Rethrow to be caught by outer catch block
          rethrow;
        }
      }
    } catch (e) {
      print('Subscription error: $e'); // Add detailed logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription error: ${e.toString()}')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the billing portal method to use Stripe
  Future<void> openBillingPortal(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // If we already have a customer ID, use it; otherwise retrieve it
      String? customerId = _stripeCustomerId;
      
      if (customerId == null) {
        // Get the customer ID from the Edge Function
        final customerResponse = await http.post(
          Uri.parse('${AppConstants.backendUrl}/get-or-create-customer'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': user.id,
            'email': user.email,
          }),
        );
        
        if (customerResponse.statusCode != 200) {
          final responseBody = customerResponse.body;
          throw json.decode(responseBody)['error'] ?? 'Failed to get customer ID';
        }
        
        customerId = json.decode(customerResponse.body)['customerId'];
        
        if (customerId == null) {
          throw 'Failed to get customer ID from server';
        }
      }

      // Print customer ID for debugging
      print('Using customer ID: $customerId');
      
      // Create a billing portal session - simplified request
      final portalResponse = await http.post(
        Uri.parse('${AppConstants.backendUrl}/create-billing-portal'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': customerId,
          // Don't send returnUrl - let the Edge Function handle it
        }),
      );
      
      print('Portal response status: ${portalResponse.statusCode}');
      print('Portal response body: ${portalResponse.body}');
      
      if (portalResponse.statusCode != 200) {
        throw json.decode(portalResponse.body)['error'] ?? 'Failed to create portal session';
      }
      
      final url = json.decode(portalResponse.body)['url'];
      
      if (url == null) {
        throw 'No portal URL returned from server';
      }
      
      print('Launching URL: $url');
      
      // Open the URL in a browser
      final canLaunchResult = await canLaunch(url);
      print('Can launch URL: $canLaunchResult');
      
      if (canLaunchResult) {
        await launch(url);
      } else {
        throw 'Could not launch Stripe portal URL';
      }
    } catch (e) {
      print('Error opening billing portal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening billing portal: ${e.toString()}')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method to your class
  Future<String?> _getAuthToken() async {
    try {
      final session = await _supabase.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }
  
  // Helper method to map app plan IDs to Stripe price IDs
  String _getPriceIdForPlan(String planId) {
    switch (planId) {
      case 'premium_monthly':
        return 'price_1RNSCoFHQ9IY1M5xrhjkyOKj'; // Replace with your actual Stripe price ID
      case 'premium_yearly':
        return 'price_1RNSCoFHQ9IY1M5x48ymUHbC'; // Replace with your actual Stripe price ID
      default:
        throw 'Invalid plan ID';
    }
  }
  
  // Keep your existing methods for refreshing data
  Future<void> refreshUsageCounts() async {
    await loadUsageCounts();
    notifyListeners();
  }

  Future<void> refreshData() async {
    try {
      await refreshUsageCounts();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }
  
  // The _simulateSubscription method from the original code can be removed
  // as we're now using real Stripe integration
}