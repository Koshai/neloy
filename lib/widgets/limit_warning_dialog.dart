import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription/subscription_screen.dart';

class LimitWarningDialog extends StatelessWidget {
  final String limitType; // 'property', 'tenant', or 'document'

  const LimitWarningDialog({required this.limitType});

  @override
  Widget build(BuildContext context) {
    final itemName = limitType == 'property' 
        ? 'properties' 
        : (limitType == 'tenant' ? 'tenants' : 'documents');
    
    final limit = limitType == 'property' 
        ? 1 
        : (limitType == 'tenant' ? 5 : 5);

    return AlertDialog(
      title: Text('Free Plan Limit Reached'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            'You\'ve reached the free plan limit of $limit $itemName.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Upgrade to Premium for unlimited $itemName and access to all premium features.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SubscriptionScreen()),
            );
          },
          child: Text('View Premium Plan'),
        ),
      ],
    );
  }
}