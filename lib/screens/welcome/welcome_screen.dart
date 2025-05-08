// This is a screen shown after login for new users to explain the free plan
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../subscription/subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to PropertyPro!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all set up with the free plan',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Free plan description
                    _buildSectionTitle('Your Free Plan Includes:'),
                    SizedBox(height: 16),
                    _buildPlanFeature(
                      context,
                      icon: Icons.home,
                      title: '1 Property',
                      description: 'Manage one property with all features',
                    ),
                    _buildPlanFeature(
                      context,
                      icon: Icons.people,
                      title: '5 Tenants',
                      description: 'Add up to five tenants to your property',
                    ),
                    _buildPlanFeature(
                      context,
                      icon: Icons.insert_drive_file,
                      title: '5 Documents',
                      description: 'Store important documents like leases, receipts',
                    ),
                    _buildPlanFeature(
                      context,
                      icon: Icons.bar_chart,
                      title: 'Financial Tracking',
                      description: 'Track rent payments and property expenses',
                    ),
                    _buildPlanFeature(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Calendar Integration',
                      description: 'See important dates for your property',
                    ),
                    SizedBox(height: 32),
                    
                    // Premium benefits
                    _buildSectionTitle('Upgrade to Premium for:'),
                    SizedBox(height: 16),
                    _buildPremiumFeature(
                      context,
                      title: 'Unlimited Properties',
                      description: 'Manage your entire property portfolio',
                    ),
                    _buildPremiumFeature(
                      context,
                      title: 'Unlimited Tenants & Documents',
                      description: 'No restrictions on tenants or file storage',
                    ),
                    _buildPremiumFeature(
                      context,
                      title: 'Advanced Reporting',
                      description: 'Detailed financial reports and analytics',
                    ),
                    SizedBox(height: 32),
                    
                    // Upgrade button
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SubscriptionScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: Text('View Premium Plans'),
                          ),
                          SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () async {
                              // Mark welcome screen as seen
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('welcome_screen_seen', true);
                              
                              // Navigate to dashboard
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => DashboardScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: Text('Continue with Free Plan'),
                          ),
                        ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPlanFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.star, color: Colors.amber),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}