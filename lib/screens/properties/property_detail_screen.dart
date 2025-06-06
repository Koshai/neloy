import 'package:flutter/material.dart';
import 'package:ghor/models/expense.dart';
import 'package:ghor/models/payment.dart';
import 'package:ghor/providers/property_provider.dart';
import 'package:ghor/screens/tenants/add_tenant_with_lease_screen.dart';
import 'package:ghor/services/database_service.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/payment_provider.dart';
import '../documents/pdf_viewer_screen.dart';
import '../documents/property_documents_screen.dart';
import '../expenses/add_expense_screen.dart';
import 'add_edit_property_screen.dart';
import 'package:intl/intl.dart';
import '../../providers/lease_provider.dart';
import '../../models/lease.dart';
import '../tenants/tenant_detail_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({required this.property});

  @override
  _PropertyDetailScreenState createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  List<Expense> _recentExpenses = [];
  List<Payment> _recentPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // First ensure full sync to avoid data inconsistencies
    _fullSyncAndLoadData();
  }

  Future<void> _fullSyncAndLoadData() async {
    setState(() => _isLoading = true);
    
    try {
      // First do a full data sync to ensure consistency across the app
      await DataSyncService().syncAll(context);
      
      // Then load property-specific data
      await _loadPropertyData();
    } catch (e) {
      print('Error loading property data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading property data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPropertyData() async {
    try {
      // Load leases for this property
      await context.read<LeaseProvider>().loadLeasesByProperty(widget.property.id);
      
      // Load expenses for this property
      await context.read<ExpenseProvider>().loadExpensesByProperty(widget.property.id);
      if (mounted) {
        setState(() {
          _recentExpenses = context.read<ExpenseProvider>().expenses.take(3).toList();
        });
      }
      
      // Find active leases for this property to load payments
      final leases = context.read<LeaseProvider>().leases;
      if (leases.isNotEmpty) {
        // For each lease, load payments
        for (final lease in leases) {
          await context.read<PaymentProvider>().loadPaymentsByLease(lease.id);
        }
        
        // Get all payments
        if (mounted) {
          setState(() {
            _recentPayments = context.read<PaymentProvider>().payments.take(3).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading property-specific data: $e');
    }
  }

  Future<void> _confirmDeleteProperty(BuildContext context) async {
    final databaseService = DatabaseService();
    final canDelete = await databaseService.canDeleteProperty(widget.property.id);
    
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete property with active tenants. Please remove tenants first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete this property? This will also delete all associated documents and expenses. This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog
                await databaseService.deleteProperty(widget.property.id);
                // Sync all data after deletion
                await DataSyncService().syncAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Property deleted successfully')),
                );
                Navigator.pop(context); // Go back to property list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting property: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Details'),
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fullSyncAndLoadData,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditPropertyScreen(property: widget.property),
                ),
              ).then((_) {
                // Refresh data when returning from edit screen
                _fullSyncAndLoadData();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeleteProperty(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Property Info Card
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.property.address,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow('Type', widget.property.propertyType),
                          if (widget.property.bedrooms != null)
                            _buildInfoRow('Bedrooms', widget.property.bedrooms.toString()),
                          if (widget.property.bathrooms != null)
                            _buildInfoRow('Bathrooms', widget.property.bathrooms.toString()),
                          if (widget.property.squareFeet != null)
                            _buildInfoRow('Square Feet', widget.property.squareFeet.toString()),
                          if (widget.property.purchasePrice != null)
                            _buildInfoRow('Purchase Price', 
                              '\$${NumberFormat('#,###').format(widget.property.purchasePrice)}'),
                          if (widget.property.currentValue != null)
                            _buildInfoRow('Current Value', 
                              '\$${NumberFormat('#,###').format(widget.property.currentValue)}'),
                        ],
                      ),
                    ),
                  ),

                  // Quick Actions
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            children: [
                              _buildActionButton(
                                'Add Tenant',
                                Icons.person_add,
                                widget.property.isAvailable ? Colors.blue : Colors.grey,
                                widget.property.isAvailable
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddTenantWithLeaseScreen(
                                            preSelectedPropertyId: widget.property.id,
                                          ),
                                        ),
                                      ).then((_) => _fullSyncAndLoadData());
                                    }
                                  : () {}, // Empty function
                              ),
                              _buildActionButton(
                                'Add Expense',
                                Icons.receipt,
                                Colors.red,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddExpenseScreen(
                                        preSelectedPropertyId: widget.property.id,
                                      ),
                                    ),
                                  ).then((_) => _fullSyncAndLoadData());
                                },
                              ),
                              _buildActionButton(
                                'View Documents',
                                Icons.folder,
                                Colors.orange,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PropertyDocumentsScreen(
                                        property: widget.property,
                                      ),
                                    ),
                                  ).then((_) => _fullSyncAndLoadData());
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Occupancy Status
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Occupancy Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.property.isAvailable ? 'Available' : 'Not Available',
                                style: TextStyle(
                                  color: widget.property.isAvailable ? Colors.green : Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await context.read<PropertyProvider>()
                                      .togglePropertyAvailability(widget.property.id);
                                  // Full sync to ensure data consistency
                                  await DataSyncService().syncAll(context);
                                  setState(() {}); // Refresh the state
                                },
                                child: Text(
                                  widget.property.isAvailable ? 'Mark as Unavailable' : 'Mark as Available',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.property.isAvailable ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rest of your code...
                  // Current Tenants section
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Tenants',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 16),
                          Consumer<LeaseProvider>(
                            builder: (context, leaseProvider, _) {
                              if (leaseProvider.isLoading) {
                                return Center(child: CircularProgressIndicator());
                              }
                              
                              final activeLeases = leaseProvider.leases
                                  .where((lease) => lease.status == 'active')
                                  .toList();
                              
                              if (activeLeases.isEmpty) {
                                return Text('No current tenants');
                              }
                              
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: activeLeases.length,
                                itemBuilder: (context, index) {
                                  final lease = activeLeases[index];
                                  return Consumer<TenantProvider>(
                                    builder: (context, tenantProvider, _) {
                                      final tenant = tenantProvider.tenants
                                          .where((t) => t.id == lease.tenantId)
                                          .firstOrNull;
                                      
                                      if (tenant == null) return SizedBox.shrink();
                                      
                                      return ListTile(
                                        leading: CircleAvatar(
                                          child: Text(
                                            '${tenant.firstName[0]}${tenant.lastName[0]}',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        title: Text('${tenant.firstName} ${tenant.lastName}'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Rent: \$${lease.rentAmount.toStringAsFixed(2)}'),
                                            Text('Lease ends: ${DateFormat('MMM dd, yyyy').format(lease.endDate)}'),
                                          ],
                                        ),
                                        isThreeLine: true,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => TenantDetailScreen(tenant: tenant),
                                            ),
                                          ).then((_) => _fullSyncAndLoadData());
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Expenses section with your existing code
                  Consumer<ExpenseProvider>(
                    builder: (context, provider, _) {
                      return Card(
                        margin: EdgeInsets.all(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Expenses',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to full expense list
                                    },
                                    child: Text('View All'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _recentExpenses.isEmpty 
                                ? Text('No recent expenses')
                                : Column(
                                    children: _recentExpenses.map((expense) => 
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.trending_down, color: Colors.white, size: 16),
                                        ),
                                        title: Text('\$${expense.amount.toStringAsFixed(2)}'),
                                        subtitle: Text('${expense.expenseType} - ${DateFormat('MMM dd, yyyy').format(expense.expenseDate)}'),
                                      )
                                    ).toList(),
                                  ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Recent Payments section with your existing code
                  Consumer<PaymentProvider>(
                    builder: (context, provider, _) {
                      return Card(
                        margin: EdgeInsets.all(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Payments',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to full payment list
                                    },
                                    child: Text('View All'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _recentPayments.isEmpty 
                                ? Text('No recent payments')
                                : Column(
                                    children: _recentPayments.map((payment) => 
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.green,
                                          child: Icon(Icons.attach_money, color: Colors.white, size: 16),
                                        ),
                                        title: Text('\$${payment.amount.toStringAsFixed(2)}'),
                                        subtitle: Text('${DateFormat('MMM dd, yyyy').format(payment.paymentDate)}'),
                                      )
                                    ).toList(),
                                  ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}