import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../utils/constants.dart';
import '../services/in_app_purchase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _plan = 'free'; // 'free', 'basic', 'premium'
  DateTime? _subscriptionExpiryDate;
  bool _showAnnualPlans = false;

  String? _currentPlanType; // 'premium_monthly' or 'premium_yearly'
  String? get currentPlanType => _currentPlanType;
  
  // Subscription-related properties
  String? _subscriptionId;
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
  
  // Updated getters for subscription info
  String? get subscriptionId => _subscriptionId;
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

  bool _needToRefreshOnResume = false;

  SubscriptionProvider() {
    // Initialize in-app purchases
    InAppPurchaseService.initialize();
    loadSubscriptionStatus();
  }

  // Update this method to load subscription data
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
        // Load subscription properties
        _subscriptionId = response['subscription_id'];
        _subscriptionStatus = response['subscription_status'];
        _cancelAtPeriodEnd = response['cancel_at_period_end'] ?? false;
        _lastPaymentError = response['last_payment_error'];
        _currentPlanType = response['subscription_plan']; // Get the plan type
        
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
            _plan = response['subscription_plan']?.startsWith('premium') ?? false 
                ? 'premium' 
                : 'free';
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

  // New method for subscription
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
            SnackBar(content: Text('You already have an active subscription. Please manage it in the account settings.')),
          );
          return; // Exit the method
        }
      } catch (e) {
        print('Error checking existing subscription: $e');
        // Continue with subscription creation anyway
      }
      
      // Get the price for the selected plan
      final double price = _getPriceForPlan(planId);
      
      // Process the purchase
      bool paymentSuccessful = false;
      
      if (kDebugMode) {
        // Use mock dialog in debug mode
        paymentSuccessful = await InAppPurchaseService.showMockPurchaseDialog(
          context, planId, price);
      } else {
        // Use real payment in release mode
        paymentSuccessful = await InAppPurchaseService.makePurchase(
          context, planId);
      }
      
      if (paymentSuccessful) {
        // Payment successful, update local state
        _plan = 'premium';
        _subscriptionExpiryDate = DateTime.now().add(planId.contains('yearly') 
            ? Duration(days: 365) 
            : Duration(days: 30));
        _subscriptionId = 'purchase_${DateTime.now().millisecondsSinceEpoch}';
        _currentPlanType = planId;

        // First check if the user has a record
final existingRecord = await _supabase
    .from('user_subscriptions')
    .select()
    .eq('user_id', user.id)
    .maybeSingle();

        if (existingRecord != null) {
          // Update existing record
          await _supabase
              .from('user_subscriptions')
              .update({
                'subscription_id': _subscriptionId,
                'subscription_plan': planId,
                'is_active': true,
                'subscription_status': 'active',
                'subscription_end_date': _subscriptionExpiryDate!.toIso8601String(),
                'current_period_start': DateTime.now().toIso8601String(),
                'current_period_end': _subscriptionExpiryDate!.toIso8601String(),
                'last_payment_date': DateTime.now().toIso8601String(),
                'last_payment_amount': price,
                'updated_at': DateTime.now().toIso8601String(),
                'cancel_at_period_end': false, // Reset cancellation if they're resubscribing
              })
              .eq('user_id', user.id);
        } else {
          // Insert new record
          await _supabase
              .from('user_subscriptions')
              .insert({
                'user_id': user.id,
                'subscription_id': _subscriptionId,
                'subscription_plan': planId,
                'is_active': true,
                'subscription_status': 'active',
                'subscription_end_date': _subscriptionExpiryDate!.toIso8601String(),
                'current_period_start': DateTime.now().toIso8601String(),
                'current_period_end': _subscriptionExpiryDate!.toIso8601String(),
                'last_payment_date': DateTime.now().toIso8601String(),
                'last_payment_amount': price,
                'updated_at': DateTime.now().toIso8601String(),
              });
        };

        // Refresh subscription data
        await loadSubscriptionStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription activated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription purchase was not completed.')),
        );
      }
    } catch (e) {
      print('Subscription error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription error: ${e.toString()}')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openBillingPortal(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // For mobile platforms, show a dialog with subscription management options
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Manage Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your subscription is active until:'),
              SizedBox(height: 8),
              Text(
                DateFormat('MMMM d, yyyy').format(_subscriptionExpiryDate ?? DateTime.now()),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('What would you like to do?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'close'),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text('Cancel Subscription'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
      
      if (action == 'cancel') {
        // Handle subscription cancellation
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Cancellation'),
            content: Text(
              'Are you sure you want to cancel your subscription? '
              'You will still have access until ${DateFormat('MMMM d, yyyy').format(_subscriptionExpiryDate ?? DateTime.now())}.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No, Keep Subscription'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Yes, Cancel'),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          await _supabase.from('user_subscriptions').update({
            'cancel_at_period_end': true,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('user_id', user.id);
          
          _cancelAtPeriodEnd = true;
          notifyListeners();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Your subscription will cancel at the end of the current period.')),
          );
        }
      }
      
      // Set flag to refresh when app becomes active again
      _needToRefreshOnResume = true;
      
    } catch (e) {
      print('Error managing subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error managing subscription: ${e.toString()}')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to map app plan IDs to prices
  double _getPriceForPlan(String planId) {
    switch (planId) {
      case 'premium_monthly':
        return 4.99;
      case 'premium_yearly':
        return 49.99;
      default:
        throw 'Invalid plan ID';
    }
  }
  
  // Helper method to get pricing text
  String getPriceText(String planId) {
    return '\$${_getPriceForPlan(planId).toStringAsFixed(2)}';
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
}