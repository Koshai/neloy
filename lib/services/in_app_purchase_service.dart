import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'dart:io' show Platform;
import '../utils/constants.dart';

class InAppPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static Completer<bool>? _currentPurchaseCompleter;
  
  // Initialize the in-app purchase service
  static Future<void> initialize() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = 
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        print('In-app purchase error: $error');
      },
    );
  }
  
  // Dispose of the subscription
  static void dispose() {
    _subscription?.cancel();
  }
  
  // Listen to purchase updates
  static void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        print('Purchase pending: ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          print('Purchase error: ${purchaseDetails.error}');
          _currentPurchaseCompleter?.complete(false);
        } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                   purchaseDetails.status == PurchaseStatus.restored) {
          // Verify purchase
          print('Purchase completed: ${purchaseDetails.productID}');
          _currentPurchaseCompleter?.complete(true);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          print('Purchase canceled: ${purchaseDetails.productID}');
          _currentPurchaseCompleter?.complete(false);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }
  
  // Make a purchase
  static Future<bool> makePurchase(BuildContext context, String planId) async {
    if (_currentPurchaseCompleter != null) {
      return false; // Purchase already in progress
    }
    
    _currentPurchaseCompleter = Completer<bool>();
    
    try {
      // Check if store is available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The store is not available')),
        );
        _currentPurchaseCompleter?.complete(false);
        _currentPurchaseCompleter = null;
        return false;
      }
      
      // Get product details
      final productId = getProductId(planId);
      final Set<String> _kIds = {productId};
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(_kIds);
          
      if (response.notFoundIDs.isNotEmpty) {
        // Product not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product $productId not found')),
        );
        _currentPurchaseCompleter?.complete(false);
        _currentPurchaseCompleter = null;
        return false;
      }
      
      if (response.productDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No products found')),
        );
        _currentPurchaseCompleter?.complete(false);
        _currentPurchaseCompleter = null;
        return false;
      }
      
      final ProductDetails productDetails = response.productDetails.first;
      print('Found product: ${productDetails.title} - ${productDetails.price}');
      
      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
      
      // Buy product
      print('Purchasing ${productDetails.id}...');
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      // Wait for purchase to complete
      final result = await _currentPurchaseCompleter!.future;
      _currentPurchaseCompleter = null;
      return result;
    } catch (e) {
      print('Error making purchase: $e');
      _currentPurchaseCompleter?.complete(false);
      _currentPurchaseCompleter = null;
      return false;
    }
  }
  
  // Get product ID from plan ID
  static String getProductId(String planId) {
    if (Platform.isIOS) {
      switch (planId) {
        case 'premium_monthly':
          return 'com.yourapp.propertymanagement.premium.monthly';
        case 'premium_yearly':
          return 'com.yourapp.propertymanagement.premium.yearly';
        default:
          return planId;
      }
    } else {
      // Android
      switch (planId) {
        case 'premium_monthly':
          return 'premium_monthly';
        case 'premium_yearly':
          return 'premium_yearly';
        default:
          return planId;
      }
    }
  }
  
  // For development/testing, show a mock payment UI
  static Future<bool> showMockPurchaseDialog(
    BuildContext context, 
    String planId, 
    double price
  ) async {
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${Platform.isIOS ? "App Store" : "Google Play"} Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payment,
              size: 50,
              color: Platform.isIOS ? Colors.blue : Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Purchase $planId Subscription',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Price: \$${price.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            Text(
              'This is a simulated purchase for development.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(false);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Platform.isIOS ? Colors.blue : Colors.green,
            ),
            child: Text(
              'Purchase',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    return await completer.future;
  }
}