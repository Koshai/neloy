import 'package:flutter/material.dart';
import 'package:ghor/models/expense.dart';
import 'package:ghor/models/property.dart';
import 'package:ghor/screens/properties/property_detail_screen.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> with WidgetsBindingObserver {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Register this as an observer
    WidgetsBinding.instance.addObserver(this);
    // Load data when first opening
    _loadDataSequentially();
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If app resumes from background, refresh data
    if (state == AppLifecycleState.resumed) {
      _loadDataSequentially();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only refresh if it's been more than 2 seconds since last refresh
      final lastSync = DataSyncService().lastFullSync;
      if (lastSync == null || 
          DateTime.now().difference(lastSync).inSeconds > 2) {
        _loadDataSequentially();
      }
    });
  }

  Future<void> _loadDataSequentially() async {
    setState(() => _isInitialLoading = true);
    
    try {
      // Use the DataSyncService for reliable sequential loading
      await DataSyncService().syncAll(context);
    } catch (e) {
      print('Error loading expense data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _confirmDeleteExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete this expense of \$${expense.amount.toStringAsFixed(2)}? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await context.read<ExpenseProvider>().deleteExpense(expense.id);
                // Always sync after data changes
                await DataSyncService().syncAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Expense deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting expense: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDataSequentially,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddExpenseScreen()),
              ).then((_) {
                // Always sync when returning from add screen
                _loadDataSequentially();
              });
            },
          ),
        ],
      ),
      body: _isInitialLoading 
          ? Center(child: CircularProgressIndicator())
          : _buildExpensesList(),
    );
  }

  Widget _buildExpensesList() {
    return Consumer2<ExpenseProvider, PropertyProvider>(
      builder: (context, expenseProvider, propertyProvider, _) {
        // Check if any provider is still loading
        final isAnyProviderLoading = expenseProvider.isLoading || propertyProvider.isLoading;
        
        if (isAnyProviderLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final expenses = expenseProvider.expenses;
        
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No expenses recorded', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Tap + to add an expense', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Pre-process and verify all relationships for better performance and error handling
        final validatedExpenses = expenses.map((expense) {
          // Find property
          final property = propertyProvider.properties.firstWhere(
            (p) => p.id == expense.propertyId,
            orElse: () {
              // Log the issue for debugging
              print('Warning: Property not found for expense ${expense.id} (propertyId: ${expense.propertyId})');
              return Property(
                id: expense.propertyId,
                userId: '',
                address: 'Unknown Property',
                propertyType: '',
                createdAt: DateTime.now(),
              );
            },
          );
          
          return {
            'expense': expense,
            'property': property,
          };
        }).toList();
        
        return ListView.builder(
          itemCount: validatedExpenses.length,
          itemBuilder: (context, index) {
            final item = validatedExpenses[index];
            final expense = item['expense'] as Expense;
            final property = item['property'] as Property;
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.trending_down, color: Colors.white),
                ),
                title: Row(
                  children: [
                    Text('\$${expense.amount.toStringAsFixed(2)}'),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home, size: 12, color: Colors.grey[700]),
                          SizedBox(width: 4),
                          Text(
                            property.address.length > 20 
                                ? '${property.address.substring(0, 18)}...' 
                                : property.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${expense.expenseType}'),
                    Text('Date: ${DateFormat('MMM dd, yyyy').format(expense.expenseDate)}'),
                    if (expense.description != null)
                      Text('${expense.description}'),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeleteExpense(context, expense),
                ),
                onTap: () {
                  // Navigate to property detail and sync when returning
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(property: property),
                    ),
                  ).then((_) {
                    _loadDataSequentially();
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}