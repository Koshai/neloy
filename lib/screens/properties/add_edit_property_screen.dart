import 'package:flutter/material.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../providers/property_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final Property? property;

  const AddEditPropertyScreen({this.property});

  @override
  _AddEditPropertyScreenState createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();

  String _selectedPropertyType = AppConstants.propertyTypes.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _addressController.text = widget.property!.address;
      _selectedPropertyType = widget.property!.propertyType;
      _bedroomsController.text = widget.property!.bedrooms?.toString() ?? '';
      _bathroomsController.text = widget.property!.bathrooms?.toString() ?? '';
      _squareFeetController.text = widget.property!.squareFeet?.toString() ?? '';
      _purchasePriceController.text = widget.property!.purchasePrice?.toString() ?? '';
      _currentValueController.text = widget.property!.currentValue?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? 'Add Property' : 'Edit Property'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPropertyType,
                decoration: InputDecoration(
                  labelText: 'Property Type',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.propertyTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPropertyType = value!);
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration: InputDecoration(
                        labelText: 'Bedrooms',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      decoration: InputDecoration(
                        labelText: 'Bathrooms',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _squareFeetController,
                decoration: InputDecoration(
                  labelText: 'Square Feet',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _purchasePriceController,
                decoration: InputDecoration(
                  labelText: 'Purchase Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _currentValueController,
                decoration: InputDecoration(
                  labelText: 'Current Value',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProperty,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(widget.property == null ? 'Add Property' : 'Save Changes'),
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

  Future<void> _saveProperty() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final property = Property(
          id: widget.property?.id ?? '',
          userId: AuthService().getCurrentUser()!.id,
          address: _addressController.text,
          propertyType: _selectedPropertyType,
          bedrooms: int.tryParse(_bedroomsController.text),
          bathrooms: int.tryParse(_bathroomsController.text),
          squareFeet: double.tryParse(_squareFeetController.text),
          purchasePrice: double.tryParse(_purchasePriceController.text),
          currentValue: double.tryParse(_currentValueController.text),
          createdAt: widget.property?.createdAt ?? DateTime.now(),
          isAvailable: widget.property?.isAvailable ?? true,
        );

        // Check if we're editing an existing property or adding a new one
        if (widget.property != null) {
          // Update existing property
          await context.read<PropertyProvider>().updateProperty(property);
        } else {
          // Add new property
          await context.read<PropertyProvider>().addProperty(context, property);
        }
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