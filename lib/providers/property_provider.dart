import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/database_service.dart';

class PropertyProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  List<Property> _properties = [];
  bool _isLoading = false;

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;

  Future<void> loadProperties() async {
    _isLoading = true;
    notifyListeners();

    try {
      _properties = await _databaseService.getProperties();
    } catch (e) {
      // Handle error
      print('Error loading properties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProperty(Property property) async {
    try {
      final newProperty = await _databaseService.addProperty(property);
      _properties.add(newProperty);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> togglePropertyAvailability(String propertyId) async {
    try {
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        final property = _properties[index];
        final updatedProperty = await _databaseService.updatePropertyAvailability(
          propertyId,
          !property.isAvailable,
        );
        _properties[index] = updatedProperty;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }
}