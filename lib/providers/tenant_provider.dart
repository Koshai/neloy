import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../services/database_service.dart';

class TenantProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  List<Tenant> _tenants = [];
  bool _isLoading = false;

  List<Tenant> get tenants => _tenants;
  bool get isLoading => _isLoading;

  Future<void> loadTenants() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tenants = await _databaseService.getTenants();
    } catch (e) {
      print('Error loading tenants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Tenant> addTenant(Tenant tenant) async {
    final newTenant = await _databaseService.addTenant(tenant);
    _tenants.add(newTenant);
    notifyListeners();
    return newTenant; // Return the saved tenant
  }
}