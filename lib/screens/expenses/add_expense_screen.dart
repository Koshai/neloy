import 'package:flutter/material.dart';
import 'package:property_management_app/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? preSelectedPropertyId;

  const AddExpenseScreen({this.preSelectedPropertyId});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedProperty;
  String? _selectedExpenseType;
  DateTime _selectedDate = DateTime.now();
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
        title: Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                    items: provider.properties.map((property) {
                      return DropdownMenuItem(
                        value: property.id,
                        child: Text(property.address),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProperty = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a property';
                      }
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedExpenseType,
                decoration: InputDecoration(
                  labelText: 'Expense Type',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.expenseTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedExpenseType = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an expense type';
                  }
                  return null;
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
                title: Text('Expense Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: OutlineInputBorder(),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Save Expense'),
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

  Future<void> _saveExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final expense = Expense(
          id: '',
          propertyId: _selectedProperty!,
          expenseType: _selectedExpenseType!,
          amount: double.parse(_amountController.text),
          expenseDate: _selectedDate,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          createdAt: DateTime.now(),
        );

        await context.read<ExpenseProvider>().addExpense(expense);
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