import 'package:flutter/material.dart';
import '../models/lease.dart';
import '../services/database_service.dart';

class LeaseProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  List<Lease> _leases = [];
  bool _isLoading = false;

  List<Lease> get leases => _leases;
  bool get isLoading => _isLoading;

  Future<Lease> addLease(Lease lease) async {
    final newLease = await _databaseService.addLease(lease);
    _leases.add(newLease);
    notifyListeners();
    return newLease;
  }

  Future<void> loadAllLeases() async {
  _isLoading = true;
  notifyListeners();

  try {
    _leases = await _databaseService.getAllLeases();
  } catch (e) {
    print('Error loading leases: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> loadLeasesByProperty(String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _leases = await _databaseService.getLeasesByProperty(propertyId);
    } catch (e) {
      print('Error loading leases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeasesByTenant(String tenantId) async {
  _isLoading = true;
  notifyListeners();

    try {
      _leases = await _databaseService.getLeasesByTenant(tenantId);
    } catch (e) {
      print('Error loading leases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Lease>> getAllLeasesForReport() async {
    if (leases.isEmpty) {
      await loadAllLeases();
    }
    return leases;
  }
}