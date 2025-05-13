import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
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
                _buildPremiumPlan(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionProvider provider) {
    final isPremium = provider.isPremium;
    final planName = provider.plan == 'premium' ? 'Premium Plan' : 'Free Plan';
    
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
                        planName,
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
                  Text('Renewal Date:'),
                  Text(
                    DateFormat('MMMM d, yyyy').format(provider.subscriptionExpiryDate!),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => provider.openBillingPortal(context),
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
                  '\$5',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'per month',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
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
            
            // Subscribe button - REPLACE THE EXISTING BUTTON WITH THIS ONE
            Center(
              child: ElevatedButton(
                onPressed: () => provider.subscribe(context, 'premium_monthly'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Upgrade to Premium',
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