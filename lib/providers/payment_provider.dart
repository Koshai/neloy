import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/database_service.dart';

class PaymentProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  Future<void> loadAllPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _databaseService.getAllPayments();
    } catch (e) {
      print('Error loading payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPaymentsByLease(String leaseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _databaseService.getPaymentsByLease(leaseId);
    } catch (e) {
      print('Error loading payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Payment> addPayment(Payment payment) async {
    try {
      final newPayment = await _databaseService.addPayment(payment);
      _payments.add(newPayment);
      notifyListeners();
      return newPayment;  // Return the created payment
    } catch (e) {
      throw e;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      final updatedPayment = await _databaseService.updatePayment(payment);
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        _payments[index] = updatedPayment;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deletePayment(String paymentId) async {
    try {
      await _databaseService.deletePayment(paymentId);
      _payments.removeWhere((payment) => payment.id == paymentId);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> refreshData() async {
    try {
      await loadAllPayments();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }
}