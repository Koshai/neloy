import 'package:flutter/material.dart';
import 'package:ghor/providers/subscription_provider.dart';
import '../models/property.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';

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

  Future<void> addProperty(BuildContext context, Property property) async {
    try {
      final newProperty = await _databaseService.addProperty(property);
      _properties.add(newProperty);
      notifyListeners();

      // Update subscription provider
      context.read<SubscriptionProvider>().refreshUsageCounts();
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

  Future<void> updateProperty(Property property) async {
    try {
      final updatedProperty = await _databaseService.updateProperty(property);
      final index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = updatedProperty;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _databaseService.deleteProperty(propertyId);
      _properties.removeWhere((property) => property.id == propertyId);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> refreshData() async {
    try {
      await loadProperties();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }
}