import 'package:flutter/material.dart';
import 'package:ghor/services/ml_kit_ocr_service.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

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
  bool _isScanning = false;
  
  final MlKitOcrService _scannerService = MlKitOcrService();
  File? _receiptImage;
  String? _rawOcrText;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scan Receipt Button
              _buildScanReceiptButton(),
              
              if (_receiptImage != null) ...[
                SizedBox(height: 16),
                _buildReceiptPreview(),
              ],
              
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
              
              // Expense Type
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
              
              // Amount
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
              
              // Date
              ListTile(
                title: Text('Expense Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: OutlineInputBorder(),
              ),
              SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: 24),
              
              // Save Button
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

  Widget _buildScanReceiptButton() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _scanReceipt,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Use your camera to scan a receipt',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scanned Receipt:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _receiptImage!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _receiptImage = null;
                      _rawOcrText = null;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_isScanning)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Scanning Receipt...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_rawOcrText != null && _rawOcrText!.isNotEmpty) ...[
          SizedBox(height: 8),
          ExpansionTile(
            title: Text('View OCR Text'),
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _rawOcrText!,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _scanReceipt() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission is required to scan receipts')),
      );
      return;
    }
    
    // Show source selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _processReceiptImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _processReceiptImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processReceiptImage(ImageSource source) async {
    try {
      final imageFile = await _scannerService.captureImage(source);
      if (imageFile == null) return;
      
      setState(() {
        _receiptImage = imageFile;
        _isScanning = true;
      });
      
      // Process the image with OCR
      final receiptData = await _scannerService.processReceiptImage(imageFile);
      
      setState(() {
        _isScanning = false;
        _rawOcrText = receiptData?.rawText;
      });
      
      if (receiptData != null) {
        // Populate form fields with extracted data
        if (receiptData.amount != null) {
          _amountController.text = receiptData.amount!.toString();
        }
        
        if (receiptData.date != null) {
          setState(() {
            _selectedDate = receiptData.date!;
          });
        }
        
        if (receiptData.description != null) {
          _descriptionController.text = receiptData.description!;
        }
        
        if (receiptData.expenseType != null) {
          setState(() {
            _selectedExpenseType = receiptData.expenseType;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt scanned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not extract information from receipt'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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