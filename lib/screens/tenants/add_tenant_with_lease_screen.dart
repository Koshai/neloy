import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tenant.dart';
import '../../models/lease.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/lease_provider.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class AddTenantWithLeaseScreen extends StatefulWidget {
  final String? preSelectedPropertyId;

  const AddTenantWithLeaseScreen({this.preSelectedPropertyId});

  @override
  _AddTenantWithLeaseScreenState createState() => _AddTenantWithLeaseScreenState();
}

class _AddTenantWithLeaseScreenState extends State<AddTenantWithLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Tenant fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Lease fields
  final _rentAmountController = TextEditingController();
  final _securityDepositController = TextEditingController();
  
  String? _selectedProperty;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 365));
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.preSelectedPropertyId;
    Future.microtask(() => 
      context.read<PropertyProvider>().loadProperties()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Tenant & Lease'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tenant Information', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              
              // Tenant fields
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter first name';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter last name';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              SizedBox(height: 32),
              Text('Lease Information', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              
              // Property selection
              Consumer<PropertyProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedProperty,
                    decoration: InputDecoration(
                      labelText: 'Property',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.properties
                        .where((property) => property.isAvailable) // Filter available properties
                        .map((property) {
                      return DropdownMenuItem(
                        value: property.id,
                        child: Text(property.address),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProperty = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Please select a property';
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              
              // Start Date
              ListTile(
                title: Text('Start Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
                shape: OutlineInputBorder(),
              ),
              SizedBox(height: 16),
              
              // End Date
              ListTile(
                title: Text('End Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
                shape: OutlineInputBorder(),
              ),
              SizedBox(height: 16),
              
              // Rent Amount
              TextFormField(
                controller: _rentAmountController,
                decoration: InputDecoration(
                  labelText: 'Monthly Rent',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter rent amount';
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Security Deposit
              TextFormField(
                controller: _securityDepositController,
                decoration: InputDecoration(
                  labelText: 'Security Deposit',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTenantAndLease,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Save Tenant & Lease'),
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

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTenantAndLease() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        // Create tenant
        final tenant = Tenant(
          id: '',
          userId: AuthService().getCurrentUser()!.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          createdAt: DateTime.now(),
        );

        final savedTenant = await context.read<TenantProvider>().addTenant(tenant);
        
        // Create lease
        final lease = Lease(
          id: '',
          propertyId: _selectedProperty!,
          tenantId: savedTenant.id,
          startDate: _startDate,
          endDate: _endDate,
          rentAmount: double.parse(_rentAmountController.text),
          securityDeposit: double.tryParse(_securityDepositController.text),
          status: 'active',
          createdAt: DateTime.now(),
        );

        await context.read<LeaseProvider>().addLease(lease);
        
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