import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/expense_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProfitLossScreen extends StatefulWidget {
  @override
  _ProfitLossScreenState createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _profitLossData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMonthlyReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profit & Loss Report'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectMonth,
                      icon: Icon(Icons.calendar_today),
                      label: Text('Change Month'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_profitLossData.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryItem(
                        'Total Income',
                        _profitLossData['income'] ?? 0,
                        Colors.green,
                      ),
                      Divider(),
                      _buildSummaryItem(
                        'Total Expenses',
                        _profitLossData['expenses'] ?? 0,
                        Colors.red,
                      ),
                      Divider(thickness: 2),
                      _buildSummaryItem(
                        'Net Profit/Loss',
                        _profitLossData['profit'] ?? 0,
                        (_profitLossData['profit'] ?? 0) > 0 ? Colors.green : Colors.red,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildProfitLossChart(),
            ] else
              Center(
                child: Text('No data available for selected month'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossChart() {
    return Container(
      height: 300,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _profitLossData['income'] ?? 0,
                  color: Colors.green,
                  width: 25,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _profitLossData['expenses'] ?? 0,
                  color: Colors.red,
                  width: 25,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Income');
                    case 1:
                      return Text('Expenses');
                    default:
                      return Text('');
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      _loadMonthlyReport();
    }
  }

  Future<void> _loadMonthlyReport() async {
    setState(() => _isLoading = true);
    try {
      // This would call your DatabaseService to get monthly data
      final income = await _calculateMonthlyIncome();
      final expenses = await _calculateMonthlyExpenses();
      
      setState(() {
        _profitLossData = {
          'income': income,
          'expenses': expenses,
          'profit': income - expenses,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading report: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<double> _calculateMonthlyIncome() async {
    // This should calculate income from payments for the selected month
    final payments = context.read<PaymentProvider>().payments
        .where((payment) => 
          payment.paymentDate.year == _selectedMonth.year &&
          payment.paymentDate.month == _selectedMonth.month)
        .toList();
    
    double total = 0;
    for (var payment in payments) {
      total += payment.amount;
    }
    return total;
  }

  Future<double> _calculateMonthlyExpenses() async {
    // This should calculate expenses for the selected month
    final expenses = context.read<ExpenseProvider>().expenses
        .where((expense) => 
          expense.expenseDate.year == _selectedMonth.year &&
          expense.expenseDate.month == _selectedMonth.month)
        .toList();
    
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }
}