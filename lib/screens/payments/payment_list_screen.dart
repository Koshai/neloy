import 'package:flutter/material.dart';
import 'package:property_management_app/models/lease.dart';
import 'package:property_management_app/models/payment.dart';
import 'package:property_management_app/models/property.dart';
import 'package:property_management_app/models/tenant.dart';
import 'package:property_management_app/screens/properties/property_detail_screen.dart';
import 'package:property_management_app/screens/tenants/tenant_detail_screen.dart';
import 'package:property_management_app/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/lease_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import 'package:intl/intl.dart';
import 'add_payment_screen.dart';
import 'package:property_management_app/main.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Add this class to hold the validated payment data
class PaymentListItem {
  final Payment payment;
  final Lease lease;
  final Property property;
  final Tenant tenant;
  
  PaymentListItem({
    required this.payment,
    required this.lease,
    required this.property,
    required this.tenant,
  });
}

class PaymentListScreen extends StatefulWidget {
  @override
  _PaymentListScreenState createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> with WidgetsBindingObserver, RouteAware {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Register this as an observer
    WidgetsBinding.instance.addObserver(this);
    // Load data when first opening
    _loadDataSequentially();
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this); // Unsubscribe from route observer
    super.dispose();
  }

  @override
  void didPush() {
    // Called when the current route has been pushed onto the navigator
    super.didPush();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route is now visible
    _loadDataSequentially(); // Refresh data when returning to this screen
    super.didPopNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If app resumes from background, refresh data
    if (state == AppLifecycleState.resumed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
      }
      _loadDataSequentially();
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only run if not already loading
        if (!_isInitialLoading && mounted) {
          _loadDataSequentially();
        }
    });
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  Future<void> _loadDataSequentially() async {
    setState(() => _isInitialLoading = true);
    
    try {
      // Use the DataSyncService for reliable sequential loading
      await DataSyncService().syncAll(context);
    } catch (e) {
      print('Error loading payment data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _confirmDeletePayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payment'),
        content: Text(
          'Are you sure you want to delete this payment of \$${payment.amount.toStringAsFixed(2)}? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await context.read<PaymentProvider>().deletePayment(payment.id);
                // Always sync after data changes
                await DataSyncService().syncAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting payment: $e')),
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
        title: Text('Rent Payments'),
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDataSequentially,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddPaymentScreen()),
              ).then((_) {
                // Always sync when returning from add screen
                _loadDataSequentially();
              });
            },
          ),
        ],
      ),
      body: _isInitialLoading 
          ? Center(child: CircularProgressIndicator())
          : _buildPaymentsList(),
    );
  }

  Widget _buildPaymentsList() {
    return Consumer4<PaymentProvider, LeaseProvider, PropertyProvider, TenantProvider>(
      builder: (context, paymentProvider, leaseProvider, propertyProvider, tenantProvider, _) {
        // Check if any provider is still loading
        final isAnyProviderLoading = paymentProvider.isLoading || 
                                    leaseProvider.isLoading || 
                                    propertyProvider.isLoading || 
                                    tenantProvider.isLoading;
        
        if (isAnyProviderLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final payments = paymentProvider.payments;
        
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payments recorded', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Tap + to add a payment', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Pre-process and verify all relationships for better performance and error handling
        final validatedPayments = payments.map((payment) {
          // Find lease
          final lease = leaseProvider.leases.firstWhere(
            (l) => l.id == payment.leaseId,
            orElse: () {
              // Log the issue for debugging
              print('Warning: Lease not found for payment ${payment.id} (leaseId: ${payment.leaseId})');
              return Lease(
                id: payment.leaseId,
                propertyId: '',
                tenantId: '',
                startDate: DateTime.now(),
                endDate: DateTime.now(),
                rentAmount: 0,
                status: 'unknown',
                createdAt: DateTime.now(),
              );
            },
          );

          // Add special handling for orphaned leases
          if (lease.id.startsWith('orphaned-')) {
            // This is an orphaned payment that will be cleaned up on next sync
            // Show a placeholder row with error indication
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red[50],  // Light red background to indicate error
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.error_outline, color: Colors.white),
                ),
                title: Text('Payment with missing data'),
                subtitle: Text('This payment has invalid references and will be removed on next sync'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeletePayment(context, payment),
                ),
              ),
            );
          }
          
          // Find property
          final property = propertyProvider.properties.firstWhere(
            (p) => p.id == lease.propertyId,
            orElse: () {
              print('Warning: Property not found for lease ${lease.id} (propertyId: ${lease.propertyId})');
              return Property(
                id: lease.propertyId,
                userId: '',
                address: 'Unknown Property',
                propertyType: '',
                createdAt: DateTime.now(),
              );
            },
          );
          
          // Find tenant
          final tenant = tenantProvider.tenants.firstWhere(
            (t) => t.id == lease.tenantId,
            orElse: () {
              print('Warning: Tenant not found for lease ${lease.id} (tenantId: ${lease.tenantId})');
              return Tenant(
                id: lease.tenantId,
                userId: '',
                firstName: 'Unknown',
                lastName: 'Tenant',
                createdAt: DateTime.now(),
              );
            },
          );
          
          // Create a properly typed map
          return PaymentListItem(payment: payment, lease: lease, property: property, tenant: tenant);
        }).toList();
        
        return ListView.builder(
          itemCount: validatedPayments.length,
          itemBuilder: (context, index) {
            final item = validatedPayments[index];
            final payment = (item as PaymentListItem).payment;
            final property = (item as PaymentListItem).property;
            final tenant = (item as PaymentListItem).tenant;

            // Special handling for orphaned data
            final bool isOrphanedData = 
                item.property.address == 'Unknown Property' || 
                (item.tenant.firstName == 'Unknown' && item.tenant.lastName == 'Tenant');
            
            if (isOrphanedData) {
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red[50],  // Light red background to indicate error
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.error_outline, color: Colors.white),
                  ),
                  title: Text('Payment with missing data'),
                  subtitle: Text('This payment has invalid references'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDeletePayment(context, item.payment),
                  ),
                ),
              );
            }
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.attach_money, color: Colors.white),
                ),
                title: Row(
                  children: [
                    Text('\$${payment.amount.toStringAsFixed(2)}'),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home, size: 12, color: Colors.grey[700]),
                          SizedBox(width: 4),
                          Text(
                            property.address.length > 15 
                                ? '${property.address.substring(0, 13)}...' 
                                : property.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: Colors.grey[700]),
                        SizedBox(width: 4),
                        Text(
                          '${tenant.firstName} ${tenant.lastName}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('Date: ${DateFormat('MMM dd, yyyy').format(payment.paymentDate)}'),
                    if (payment.paymentMethod != null)
                      Text('Method: ${payment.paymentMethod}'),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeletePayment(context, payment),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Payment Details'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount: \$${payment.amount.toStringAsFixed(2)}', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Date: ${DateFormat('MMMM d, yyyy').format(payment.paymentDate)}'),
                          Text('Method: ${payment.paymentMethod ?? 'N/A'}'),
                          if (payment.notes != null) ...[
                            SizedBox(height: 8),
                            Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(payment.notes!),
                          ],
                          Divider(),
                          Text('Property: ${property.address}'),
                          Text('Tenant: ${tenant.firstName} ${tenant.lastName}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyDetailScreen(property: property),
                              ),
                            ).then((_) {
                              // Sync when returning from property detail
                              _loadDataSequentially();
                            });
                          },
                          child: Text('View Property'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TenantDetailScreen(tenant: tenant),
                              ),
                            ).then((_) {
                              // Sync when returning from tenant detail
                              _loadDataSequentially();
                            });
                          },
                          child: Text('View Tenant'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}