import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _plan = 'free'; // 'free', 'basic', 'premium'
  DateTime? _subscriptionExpiryDate;
  bool _showAnnualPlans = false;
  
  // Freemium limits
  final int _freePropertyLimit = 1;
  final int _freeTenantLimit = 5;
  final int _freeDocumentLimit = 5;
  
  // Current usage
  int _propertyCount = 0;
  int _tenantCount = 0;
  int _documentCount = 0;

  bool get isLoading => _isLoading;
  String get plan => _plan;
  bool get isPremium => _plan != 'free';
  bool get showAnnualPlans => _showAnnualPlans;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;
  
  // Getter for limits
  int get propertyLimit => isPremium ? 999 : _freePropertyLimit;
  int get tenantLimit => isPremium ? 999 : _freeTenantLimit;
  int get documentLimit => isPremium ? 999 : _freeDocumentLimit;
  
  // Getters for current usage
  int get propertyCount => _propertyCount;
  int get tenantCount => _tenantCount;
  int get documentCount => _documentCount;
  
  // Getters for remaining limits
  int get remainingProperties => propertyLimit - _propertyCount;
  int get remainingTenants => tenantLimit - _tenantCount;
  int get remainingDocuments => documentLimit - _documentCount;
  
  // Check if limits are reached
  bool get canAddProperty => isPremium || _propertyCount < _freePropertyLimit;
  bool get canAddTenant => isPremium || _tenantCount < _freeTenantLimit;
  bool get canAddDocument => isPremium || _documentCount < _freeDocumentLimit;

  SubscriptionProvider() {
    loadSubscriptionStatus();
  }

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
        // Check if has active subscription
        final subscriptionEndStr = response['subscription_end_date'];
        if (subscriptionEndStr != null) {
          _subscriptionExpiryDate = DateTime.parse(subscriptionEndStr);
          final isActive = _subscriptionExpiryDate!.isAfter(DateTime.now());
          
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

  Future<void> subscribe(BuildContext context, String planId) async {
  // In a real app, this would integrate with your payment processor
  // For this example, we'll just show a dialog
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('In a real app, this would take you to the payment screen for the Premium plan.'),
            SizedBox(height: 16),
            Text(
              'You would be charged \$5/month for unlimited properties, tenants, and documents.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulate successful subscription
              _simulateSubscription('premium');
            },
            child: Text('Simulate Premium Upgrade'),
          ),
        ],
      ),
    );
  }

  void _simulateSubscription(String planType) {
    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    Future.delayed(Duration(seconds: 1), () async {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      try {
        // Set subscription details
        final now = DateTime.now();
        final endDate = now.add(Duration(days: 30)); // 30-day subscription

        await _supabase.from('user_subscriptions').upsert({
          'user_id': user.id,
          'subscription_plan': planType,
          'subscription_end_date': endDate.toIso8601String(),
          'is_active': true,
        });

        _plan = planType;
        _subscriptionExpiryDate = endDate;
      } catch (e) {
        print('Error updating subscription: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> openBillingPortal(BuildContext context) async {
    // In a real app, this would open your payment processor's billing portal
    // For this example, we'll just show a dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Billing Portal'),
        content: Text('In a real app, this would redirect you to the billing portal to manage your subscription.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Call this whenever properties, tenants, or documents are added or removed
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