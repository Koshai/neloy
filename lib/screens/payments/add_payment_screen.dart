import 'package:flutter/material.dart';
import 'package:ghor/providers/lease_provider.dart';
import 'package:ghor/providers/property_provider.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class AddPaymentScreen extends StatefulWidget {
  @override
  _AddPaymentScreenState createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
   String? _selectedTenant;
  String? _selectedLease;
  String? _selectedPaymentMethod;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TenantProvider>().loadTenants();
      context.read<LeaseProvider>().loadAllLeases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Payment'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Consumer<TenantProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedTenant,
                    decoration: InputDecoration(
                      labelText: 'Tenant',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.tenants.map((tenant) {
                      return DropdownMenuItem(
                        value: tenant.id,
                        child: Text('${tenant.firstName} ${tenant.lastName}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTenant = value;
                        _selectedLease = null; // Reset lease when tenant changes
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a tenant';
                      }
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              // Add lease selection dropdown
              if (_selectedTenant != null)
                Consumer<LeaseProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    final activeLeases = provider.leases
                        .where((lease) => 
                          lease.tenantId == _selectedTenant && 
                          lease.status == 'active')
                        .toList();
                    
                    if (activeLeases.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No active leases found for this tenant',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    
                    return Consumer<PropertyProvider>(
                      builder: (context, propertyProvider, _) {
                        return DropdownButtonFormField<String>(
                          value: _selectedLease,
                          decoration: InputDecoration(
                            labelText: 'Lease/Property',
                            border: OutlineInputBorder(),
                          ),
                          items: activeLeases.map((lease) {
                            // Get property info
                            final property = propertyProvider.properties
                                .where((p) => p.id == lease.propertyId)
                                .firstOrNull;
                                
                            final propertyName = property?.address ?? 'Unknown property';
                            
                            return DropdownMenuItem(
                              value: lease.id,
                              child: Text('$propertyName - \$${lease.rentAmount}/month'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedLease = value);
                            
                            // Pre-fill amount with lease rent
                            if (value != null) {
                              final lease = provider.leases
                                  .firstWhere((l) => l.id == value);
                              _amountController.text = lease.rentAmount.toString();
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a lease';
                            }
                            return null;
                          },
                        );
                      }
                    );
                  },
                ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Payment Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: OutlineInputBorder(),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value);
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePayment,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Save Payment'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        // We need to use the actual selected lease ID
        if (_selectedLease == null) {
          throw 'Please select a lease';
        }
        
        final payment = Payment(
          id: '',
          leaseId: _selectedLease!, // Using the selected lease ID
          amount: double.parse(_amountController.text),
          paymentDate: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: DateTime.now(),
        );

        await context.read<PaymentProvider>().addPayment(payment);
        await DataSyncService().syncAll(context);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}