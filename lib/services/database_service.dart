import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../models/lease.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import '../services/file_storage_service.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;
  final _fileStorage = FileStorageService();

  // Properties
  Future<List<Property>> getProperties() async {
    final response = await _supabase
        .from('properties')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Property.fromJson(item))
        .toList();
  }

  Future<Property> addProperty(Property property) async {
    final response = await _supabase
        .from('properties')
        .insert(property.toJson())
        .select()
        .single();

    return Property.fromJson(response);
  }

  // Leases
  Future<Lease> addLease(Lease lease) async {
    final response = await _supabase
        .from('leases')
        .insert(lease.toJson())
        .select()
        .single();

    return Lease.fromJson(response);
  }

  Future<List<Lease>> getLeasesByProperty(String propertyId) async {
    final response = await _supabase
        .from('leases')
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Lease.fromJson(item))
        .toList();
  }

  Future<List<Lease>> getLeasesByTenant(String tenantId) async {
    final response = await _supabase
        .from('leases')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Lease.fromJson(item))
        .toList();
  }

  Future<List<Lease>> getExpiredLeases(DateTime currentDate) async {
    final response = await _supabase
        .from('leases')
        .select()
        .eq('status', 'active')
        .lte('end_date', currentDate.toIso8601String());

    return (response as List)
        .map((item) => Lease.fromJson(item))
        .toList();
  }

  Future<List<Lease>> getAllLeases() async {
    final response = await _supabase
        .from('leases')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Lease.fromJson(item))
        .toList();
  }

  Future<void> updateLeaseStatus(String leaseId, String status) async {
    await _supabase
        .from('leases')
        .update({'status': status})
        .eq('id', leaseId);
  }

  Future<void> updateTenantStatus(String tenantId, String status) async {
    // You'll need to add this column to your tenants table
    await _supabase
        .from('tenants')
        .update({'status': status})
        .eq('id', tenantId);
  }

  Future<Property> updatePropertyAvailability(String propertyId, bool isAvailable) async {
    final response = await _supabase
        .from('properties')
        .update({'is_available': isAvailable})
        .eq('id', propertyId)
        .select()
        .single();

    return Property.fromJson(response);
  }

  // Documents
  Future<List<Document>> getTenantDocuments(String tenantId) async {
    final response = await _supabase
        .from('documents')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Document.fromJson(item))
        .toList();
  }

  Future<List<Document>> getPropertyDocuments(String propertyId) async {
    final response = await _supabase
        .from('documents')
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Document.fromJson(item))
        .toList();
  }

  Future<void> deleteDocument(String documentId) async {
    // First get the document to find its file path
    final docResponse = await _supabase
        .from('documents')
        .select()
        .eq('id', documentId)
        .single();
    
    if (docResponse != null) {
      final document = Document.fromJson(docResponse);
      
      // Delete the local file
      String bucket;
      if (document.tenantId != null) {
        bucket = 'tenant-documents';
      } else if (document.propertyId != null) {
        bucket = 'property-documents';
      } else {
        bucket = 'general-documents';
      }
      
      await _fileStorage.deleteFile(
        bucket: bucket,
        path: document.filePath,
      );
      
      print('LOCAL_STORAGE: Deleted local file for document: ${document.fileName}');
    }
    
    // Then delete from database
    await _supabase
        .from('documents')
        .delete()
        .eq('id', documentId);
  }

  Future<Property> updateProperty(Property property) async {
    final response = await _supabase
        .from('properties')
        .update(property.toJson())
        .eq('id', property.id)
        .select()
        .single();

    return Property.fromJson(response);
  }

  Future<bool> canDeleteProperty(String propertyId) async {
    // Check if there are active leases for this property
    final response = await _supabase
        .from('leases')
        .select('id')
        .eq('property_id', propertyId)
        .eq('status', 'active');
    
    return (response as List).isEmpty;
  }

  Future<void> deleteProperty(String propertyId) async {
    // First delete associated local document files
    final documents = await getPropertyDocuments(propertyId);
    for (final document in documents) {
      await _fileStorage.deleteFile(
        bucket: 'property-documents',
        path: document.filePath,
      );
      print('LOCAL_STORAGE: Deleted local file for property document: ${document.fileName}');
    }
    
    // Then delete associated documents from database
    await _supabase
        .from('documents')
        .delete()
        .eq('property_id', propertyId);
        
    // Delete property expenses
    await _supabase
        .from('expenses')
        .delete()
        .eq('property_id', propertyId);
        
    // Delete property
    await _supabase
        .from('properties')
        .delete()
        .eq('id', propertyId);
        
    print('LOCAL_STORAGE: Completed property deletion with local file cleanup');
  }

  Future<Document> addDocument({
    String? tenantId,
    String? propertyId,  // Changed from required to optional
    required String documentType,
    required String filePath,
    required String fileName,
  }) async {
    final response = await _supabase
        .from('documents')
        .insert({
          'user_id': _supabase.auth.currentUser!.id,
          'tenant_id': tenantId,
          'property_id': propertyId,
          'document_type': documentType,
          'file_path': filePath,
          'file_name': fileName,
        })
        .select()
        .single();

    return Document.fromJson(response);
  }

  // Tenants
  Future<Tenant> addTenant(Tenant tenant) async {
    final response = await _supabase
        .from('tenants')
        .insert(tenant.toJson())
        .select()
        .single();

    return Tenant.fromJson(response);
  }

  // Tenants
  Future<List<Tenant>> getTenants() async {
    final response = await _supabase
        .from('tenants')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Tenant.fromJson(item))
        .toList();
  }

  Future<Tenant> updateTenant(Tenant tenant) async {
    final response = await _supabase
        .from('tenants')
        .update(tenant.toJson())
        .eq('id', tenant.id)
        .select()
        .single();

    return Tenant.fromJson(response);
  }

  Future<void> deleteTenant(String tenantId) async {
    // First delete associated local document files
    final documents = await getTenantDocuments(tenantId);
    for (final document in documents) {
      await _fileStorage.deleteFile(
        bucket: 'tenant-documents',
        path: document.filePath,
      );
      print('LOCAL_STORAGE: Deleted local file for tenant document: ${document.fileName}');
    }
    
    // First get all leases for this tenant
    final leases = await _supabase
        .from('leases')
        .select('id')
        .eq('tenant_id', tenantId);
        
    // Delete associated payments
    for (var lease in leases) {
      await _supabase
          .from('payments')
          .delete()
          .eq('lease_id', lease['id']);
    }
    
    // Delete leases
    await _supabase
        .from('leases')
        .delete()
        .eq('tenant_id', tenantId);
        
    // Delete documents from database
    await _supabase
        .from('documents')
        .delete()
        .eq('tenant_id', tenantId);
        
    // Delete tenant
    await _supabase
        .from('tenants')
        .delete()
        .eq('id', tenantId);
        
    print('LOCAL_STORAGE: Completed tenant deletion with local file cleanup');
  }

  // Payments
  Future<List<Payment>> getPaymentsByLease(String leaseId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('lease_id', leaseId)
        .order('payment_date', ascending: false);

    return (response as List)
        .map((item) => Payment.fromJson(item))
        .toList();
  }

  Future<Payment> addPayment(Payment payment) async {
    final response = await _supabase
        .from('payments')
        .insert(payment.toJson())
        .select()
        .single();

    return Payment.fromJson(response);
  }

  Future<List<Payment>> getAllPayments() async {
    final response = await _supabase
        .from('payments')
        .select()
        .order('payment_date', ascending: false);

    return (response as List)
        .map((item) => Payment.fromJson(item))
        .toList();
  }

  Future<Payment> updatePayment(Payment payment) async {
    final response = await _supabase
        .from('payments')
        .update(payment.toJson())
        .eq('id', payment.id)
        .select()
        .single();

    return Payment.fromJson(response);
  }

  Future<void> deletePayment(String paymentId) async {
    await _supabase
        .from('payments')
        .delete()
        .eq('id', paymentId);
  }

  // Expenses
  Future<List<Expense>> getExpensesByProperty(String propertyId) async {
    final response = await _supabase
        .from('expenses')
        .select()
        .eq('property_id', propertyId)
        .order('expense_date', ascending: false);

    return (response as List)
        .map((item) => Expense.fromJson(item))
        .toList();
  }

  Future<Expense> addExpense(Expense expense) async {
    final response = await _supabase
        .from('expenses')
        .insert(expense.toJson())
        .select()
        .single();

    return Expense.fromJson(response);
  }

  Future<List<Expense>> getAllExpenses() async {
    final response = await _supabase
        .from('expenses')
        .select()
        .order('expense_date', ascending: false);

    return (response as List)
        .map((item) => Expense.fromJson(item))
        .toList();
  }

  Future<Expense> updateExpense(Expense expense) async {
    final response = await _supabase
        .from('expenses')
        .update(expense.toJson())
        .eq('id', expense.id)
        .select()
        .single();

    return Expense.fromJson(response);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _supabase
        .from('expenses')
        .delete()
        .eq('id', expenseId);
  }

  // Profit/Loss calculations
  Future<Map<String, double>> getProfitLossForMonth(int year, int month) async {
    // Get income from payments
    final incomeResponse = await _supabase
        .from('payments')
        .select('amount')
        .contains('payment_date', '"$year-${month.toString().padLeft(2, '0')}"');

    double totalIncome = 0;
    for (var item in incomeResponse) {
      totalIncome += item['amount'] as double;
    }

    // Get expenses
    final expenseResponse = await _supabase
        .from('expenses')
        .select('amount')
        .contains('expense_date', '"$year-${month.toString().padLeft(2, '0')}"');

    double totalExpenses = 0;
    for (var item in expenseResponse) {
      totalExpenses += item['amount'] as double;
    }

    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'profit': totalIncome - totalExpenses,
    };
  }

  // COMMENTED OUT - CLOUD STORAGE CLEANUP METHODS (FOR FUTURE USE)
  /*
  // These methods would be used if switching from cloud storage to local storage
  
  Future<void> cleanupCloudStorageForProperty(String propertyId) async {
    // Get all documents for this property
    final documents = await getPropertyDocuments(propertyId);
    
    // Delete each file from cloud storage
    for (final document in documents) {
      try {
        await _supabase.storage
            .from('property-documents')
            .remove([document.filePath]);
        print('CLOUD_CLEANUP: Deleted cloud file: ${document.filePath}');
      } catch (e) {
        print('CLOUD_CLEANUP ERROR: Failed to delete ${document.filePath}: $e');
      }
    }
  }

  Future<void> cleanupCloudStorageForTenant(String tenantId) async {
    // Get all documents for this tenant
    final documents = await getTenantDocuments(tenantId);
    
    // Delete each file from cloud storage
    for (final document in documents) {
      try {
        await _supabase.storage
            .from('tenant-documents')
            .remove([document.filePath]);
        print('CLOUD_CLEANUP: Deleted cloud file: ${document.filePath}');
      } catch (e) {
        print('CLOUD_CLEANUP ERROR: Failed to delete ${document.filePath}: $e');
      }
    }
  }

  Future<void> migrateAllFilesFromCloudToLocal() async {
    // This method would migrate all existing cloud files to local storage
    // Implementation would involve:
    // 1. Download each file from cloud storage
    // 2. Save to local storage with encryption
    // 3. Update database with new file paths
    // 4. Delete from cloud storage
    // 5. Update file path format in database
  }
  */
}