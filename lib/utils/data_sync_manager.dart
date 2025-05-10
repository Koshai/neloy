// Create new file: lib/utils/data_sync_service.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/lease_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/subscription_provider.dart';

class DataSyncService {
  // Singleton pattern
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  DateTime? _lastFullSync;
  DateTime? get lastFullSync => _lastFullSync;
  
  // A complete sync reloads all app data in the correct sequence
  Future<void> syncAll(BuildContext context) async {
    if (_isSyncing) {
      print('DATA_SYNC: Already syncing, skipping duplicate request');
      return;
    }
    
    _isSyncing = true;
    print('DATA_SYNC: Starting full data synchronization');
    
    try {
      // Load all data first
      final propertyProvider = context.read<PropertyProvider>();
      final tenantProvider = context.read<TenantProvider>();
      final leaseProvider = context.read<LeaseProvider>();
      final paymentProvider = context.read<PaymentProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      
      // STEP 1: Load base entities
      print('DATA_SYNC: Loading properties');
      await propertyProvider.loadProperties();
      
      print('DATA_SYNC: Loading tenants');
      await tenantProvider.loadTenants();
      
      // STEP 2: Load relationships
      print('DATA_SYNC: Loading leases');
      await leaseProvider.loadAllLeases();
      
      // STEP 3: Load financial data
      print('DATA_SYNC: Loading payments');
      await paymentProvider.loadAllPayments();
      
      print('DATA_SYNC: Loading expenses');
      await expenseProvider.loadAllExpenses();
      
      // STEP 4: Update subscription counts
      print('DATA_SYNC: Updating subscription counts');
      await context.read<SubscriptionProvider>().refreshUsageCounts();
      
      // NEW STEP 5: Clean up orphaned data
      await cleanupOrphanedData(context);
      
      _lastFullSync = DateTime.now();
      print('DATA_SYNC: Full sync completed at ${_lastFullSync.toString()}');
    } catch (e) {
      print('DATA_SYNC ERROR: Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> cleanupOrphanedData(BuildContext context) async {
    print('DATA_SYNC: Running orphaned data cleanup');
    
    try {
      final paymentProvider = context.read<PaymentProvider>();
      final leaseProvider = context.read<LeaseProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      final propertyProvider = context.read<PropertyProvider>();
      
      // Get collections
      final payments = paymentProvider.payments;
      final leases = leaseProvider.leases;
      final expenses = expenseProvider.expenses;
      final properties = propertyProvider.properties;
      
      // Debug: Print all lease IDs to verify what's in memory
      print('DATA_SYNC: Available leases: ${leases.map((l) => l.id).join(', ')}');
      
      // 1. Find orphaned payments (with lease IDs that don't exist)
      final orphanedPayments = payments.where((payment) {
        final leaseExists = leases.any((lease) => lease.id == payment.leaseId);
        if (!leaseExists) {
          print('DATA_SYNC: Found orphaned payment ${payment.id} with non-existent lease ${payment.leaseId}');
        }
        return !leaseExists;
      }).toList();
      
      // 2. Find payments with corrupted lease references
      final corruptedPayments = payments.where((payment) {
        // Check if a lease exists but has empty property or tenant
        final matchingLeases = leases.where((l) => l.id == payment.leaseId).toList();
        
        if (matchingLeases.isEmpty) {
          // No matching lease found
          return false; // This will be caught by the orphanedPayments check
        }
        
        final lease = matchingLeases.first;
        if (lease.propertyId.isEmpty || lease.tenantId.isEmpty) {
          print('DATA_SYNC: Found payment ${payment.id} with corrupted lease ${lease.id} (propertyId: ${lease.propertyId}, tenantId: ${lease.tenantId})');
          return true;
        }
        return false;
      }).toList();
      
      // 3. Find expenses with missing property references
      final orphanedExpenses = expenses.where((expense) {
        final propertyExists = properties.any((property) => property.id == expense.propertyId);
        if (!propertyExists) {
          print('DATA_SYNC: Found orphaned expense ${expense.id} with non-existent property ${expense.propertyId}');
        }
        return !propertyExists;
      }).toList();
      
      // Delete orphaned data
      if (orphanedPayments.isNotEmpty) {
        print('DATA_SYNC: Deleting ${orphanedPayments.length} orphaned payments');
        for (final payment in orphanedPayments) {
          print('DATA_SYNC: Deleting orphaned payment ${payment.id}');
          await paymentProvider.deletePayment(payment.id);
        }
      } else {
        print('DATA_SYNC: No orphaned payments found');
      }
      
      if (corruptedPayments.isNotEmpty) {
        print('DATA_SYNC: Deleting ${corruptedPayments.length} payments with corrupted lease references');
        for (final payment in corruptedPayments) {
          print('DATA_SYNC: Deleting payment with corrupted lease reference: ${payment.id}');
          await paymentProvider.deletePayment(payment.id);
        }
      } else {
        print('DATA_SYNC: No payments with corrupted lease references found');
      }
      
      if (orphanedExpenses.isNotEmpty) {
        print('DATA_SYNC: Deleting ${orphanedExpenses.length} orphaned expenses');
        for (final expense in orphanedExpenses) {
          print('DATA_SYNC: Deleting orphaned expense ${expense.id}');
          await expenseProvider.deleteExpense(expense.id);
        }
      } else {
        print('DATA_SYNC: No orphaned expenses found');
      }
      
      // Report cleanup results
      print('DATA_SYNC: Data cleanup complete');
      
    } catch (e) {
      print('DATA_SYNC ERROR: Error during orphaned data cleanup: $e');
    }
  }
  
  void _showSyncFailureMessage(BuildContext context, String error) {
    // Only show if the context is still valid
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync data: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}