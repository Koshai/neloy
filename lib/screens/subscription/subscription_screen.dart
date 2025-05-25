import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with WidgetsBindingObserver {
  bool _needManualRefresh = false;

  @override
  void initState() {
    super.initState();
    // Register observer to detect when app returns to foreground
    WidgetsBinding.instance.addObserver(this);
    
    // Refresh data when screen first opens
    _refreshData();
  }
  
  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns to foreground, refresh data
    if (state == AppLifecycleState.resumed) {
      print('App resumed - refreshing subscription data');
      _refreshData();
      
      // Set flag to refresh again after a delay
      // This helps with cases where the first refresh happens too quickly
      if (_needManualRefresh) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            print('Performing delayed refresh after resume');
            _refreshData();
            _needManualRefresh = false;
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // App is paused (likely user went to payment screen)
      _needManualRefresh = true;
    }
  }
  
  Future<void> _refreshData() async {
    // Refresh subscription data
    await Provider.of<SubscriptionProvider>(context, listen: false).loadSubscriptionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription'),
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh subscription data',
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: EdgeInsets.all(24),
              children: [
                // Current plan info
                _buildCurrentPlanCard(context, provider),
                SizedBox(height: 24),
                
                // Usage stats
                _buildUsageStats(context, provider),
                SizedBox(height: 24),
                
                // Premium plan option if on free plan
                if (provider.plan == 'free')
                  _buildSubscriptionToggle(context, provider),
                  
                // Premium plan option if on free plan
                if (provider.plan == 'free')
                  _buildPremiumPlan(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSubscriptionToggle(BuildContext context, SubscriptionProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Billing Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  'Monthly',
                  style: TextStyle(
                    fontWeight: provider.showAnnualPlans ? FontWeight.normal : FontWeight.bold,
                    color: provider.showAnnualPlans ? Colors.grey : Colors.blue[800],
                  ),
                ),
                Switch(
                  value: provider.showAnnualPlans,
                  onChanged: (_) => provider.togglePlanType(),
                  activeColor: Colors.green,
                ),
                Text(
                  'Annual',
                  style: TextStyle(
                    fontWeight: provider.showAnnualPlans ? FontWeight.bold : FontWeight.normal,
                    color: provider.showAnnualPlans ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionProvider provider) {
    final isPremium = provider.isPremium;
    final planName = provider.plan == 'premium' ? 'Premium Plan' : 'Free Plan';
    
    // Determine billing interval (monthly or yearly)
    final String planInterval = isPremium && provider.currentPlanType?.contains('yearly') == true 
        ? ' (Annual)' 
        : (isPremium ? ' (Monthly)' : '');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPremium ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.star_border,
                  size: 48,
                  color: isPremium ? Colors.amber : Colors.grey,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        planName + planInterval,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isPremium ? Colors.blue[800] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPremium) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Next Billing Date:'),
                  Text(
                    provider.subscriptionExpiryDate != null 
                        ? DateFormat('MMMM d, yyyy').format(provider.subscriptionExpiryDate!) 
                        : 'Not available',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (provider.lastPaymentDate != null) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Last Payment:'),
                    Text(
                      DateFormat('MMMM d, yyyy').format(provider.lastPaymentDate!),
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ],
              if (provider.cancelAtPeriodEnd) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your subscription will cancel at the end of the current period.',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await provider.openBillingPortal(context);
                  
                  // After returning from the portal, refresh data after a delay
                  // This helps when the deep link doesn't trigger properly
                  Future.delayed(Duration(seconds: 1), () {
                    if (mounted) {
                      _refreshData();
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Manage Subscription'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStats(BuildContext context, SubscriptionProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildUsageItem(
              context,
              title: 'Properties',
              current: provider.propertyCount,
              limit: provider.propertyLimit,
              icon: Icons.home,
            ),
            SizedBox(height: 16),
            _buildUsageItem(
              context,
              title: 'Tenants',
              current: provider.tenantCount,
              limit: provider.tenantLimit,
              icon: Icons.people,
            ),
            SizedBox(height: 16),
            _buildUsageItem(
              context,
              title: 'Documents',
              current: provider.documentCount,
              limit: provider.documentLimit,
              icon: Icons.file_copy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context, {
    required String title,
    required int current,
    required int limit,
    required IconData icon,
  }) {
    final unlimited = limit >= 999;
    final percentage = unlimited ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final isApproachingLimit = percentage >= 0.8;
    final isAtLimit = percentage >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                SizedBox(width: 8),
                Text(title),
              ],
            ),
            Text(
              unlimited 
                  ? '$current / Unlimited' 
                  : '$current / $limit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAtLimit 
                    ? Colors.red 
                    : (isApproachingLimit ? Colors.orange : null),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (!unlimited)
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isAtLimit 
                  ? Colors.red 
                  : (isApproachingLimit ? Colors.orange : Colors.blue),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumPlan(BuildContext context, SubscriptionProvider provider) {
    // Get pricing based on plan type
    final isAnnual = provider.showAnnualPlans;
    final planPrice = isAnnual ? provider.getPriceText('premium_yearly') : provider.getPriceText('premium_monthly');
    final billingPeriod = isAnnual ? 'per year' : 'per month';
    final planId = isAnnual ? 'premium_yearly' : 'premium_monthly';
    final savingsText = isAnnual ? 'Save 17% compared to monthly plan' : '';
    
    // Determine payment method logo
    Widget paymentLogo = SizedBox.shrink();
    if (Platform.isIOS) {
      paymentLogo = Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Image.asset(
          'assets/images/apple_pay.png',
          height: 24,
        ),
      );
    } else if (Platform.isAndroid) {
      paymentLogo = Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Image.asset(
          'assets/images/google_pay.png',
          height: 24,
        ),
      );
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium label
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Plan title and price
            Text(
              'Premium Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  planPrice,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  billingPeriod,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (isAnnual && savingsText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  savingsText,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 24),
            
            // Features
            _buildFeatureItem('Unlimited properties'),
            _buildFeatureItem('Unlimited tenants'),
            _buildFeatureItem('Unlimited document storage'),
            _buildFeatureItem('Financial tracking'),
            _buildFeatureItem('Calendar integration'),
            _buildFeatureItem('Priority support'),
            
            SizedBox(height: 24),
            
            // Subscribe button
            Center(
              child: ElevatedButton(
                onPressed: provider.isLoading 
                    ? null 
                    : () async {
                  await provider.subscribe(context, planId);
                  
                  // After subscription attempt, refresh data
                  if (mounted) {
                    Future.delayed(Duration(seconds: 1), () {
                      _refreshData();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: Platform.isIOS ? Colors.black : Colors.blue,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      Platform.isIOS 
                          ? 'assets/images/apple_pay.png'
                          : 'assets/images/google_pay.png',
                      height: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Subscribe ${planPrice}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}