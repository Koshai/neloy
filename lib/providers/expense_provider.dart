import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> loadAllExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all expenses for the current user
      _expenses = await _databaseService.getAllExpenses();
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpensesByProperty(String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _databaseService.getExpensesByProperty(propertyId);
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Expense> addExpense(Expense expense) async {
    try {
      final newExpense = await _databaseService.addExpense(expense);
      _expenses.add(newExpense);
      notifyListeners();
      return newExpense;  // Return the created expense
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final updatedExpense = await _databaseService.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _databaseService.deleteExpense(expenseId);
      _expenses.removeWhere((expense) => expense.id == expenseId);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}