import 'package:flutter/material.dart';
import 'package:property_management_app/models/expense.dart';
import 'package:property_management_app/models/payment.dart';
import 'package:property_management_app/providers/property_provider.dart';
import 'package:property_management_app/screens/tenants/add_tenant_with_lease_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPropertyData();
  }

  Future<void> _loadPropertyData() async {
    // Load leases for this property
    await context.read<LeaseProvider>().loadLeasesByProperty(widget.property.id);
    
    // Load expenses for this property
    await context.read<ExpenseProvider>().loadExpensesByProperty(widget.property.id);
    setState(() {
      _recentExpenses = context.read<ExpenseProvider>().expenses.take(3).toList();
    });
    
    // Find active leases for this property to load payments
    final leases = context.read<LeaseProvider>().leases;
    if (leases.isNotEmpty) {
      // For each lease, load payments
      for (final lease in leases) {
        await context.read<PaymentProvider>().loadPaymentsByLease(lease.id);
      }
      
      // Get all payments
      setState(() {
        _recentPayments = context.read<PaymentProvider>().payments.take(3).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditPropertyScreen(property: widget.property),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                                );
                              }
                            : () {}, // Provide an empty function to satisfy non-nullable VoidCallback
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
                            );
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
                            );
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

            // Add Current Tenants section:
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
                                    );
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

            // Recent Expenses
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

            // Recent Payments
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