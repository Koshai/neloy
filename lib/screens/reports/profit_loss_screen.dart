import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/lease_provider.dart';
import '../../models/property.dart';
import '../../models/payment.dart';
import '../../models/expense.dart';
import '../../models/lease.dart';
import '../../utils/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProfitLossScreen extends StatefulWidget {
  @override
  _ProfitLossScreenState createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic> _overallData = {};
  Map<String, Map<String, dynamic>> _propertyData = {};
  bool _isLoading = false;
  String? _selectedPropertyId;
  late TabController _tabController;

  // Expense categories from AppConstants
  List<String> expenseCategories = AppConstants.expenseTypes;
  List<Color> categoryColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overall P&L'),
            Tab(text: 'Property P&L'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overall P&L Tab
          _buildOverallTab(),
          
          // Property-specific P&L Tab
          _buildPropertyTab(),
        ],
      ),
    );
  }

  Widget _buildOverallTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Date selection card
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
          else if (_overallData.isNotEmpty) ...[
            // Summary card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Divider(),
                    _buildSummaryItem(
                      'Total Income',
                      _overallData['totalIncome'] ?? 0,
                      Colors.green,
                    ),
                    Divider(),
                    _buildSummaryItem(
                      'Total Expenses',
                      _overallData['totalExpenses'] ?? 0,
                      Colors.red,
                    ),
                    Divider(thickness: 2),
                    _buildSummaryItem(
                      'Net Profit/Loss',
                      _overallData['netProfit'] ?? 0,
                      (_overallData['netProfit'] ?? 0) > 0 ? Colors.green : Colors.red,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Income Details
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Rental Income',
                      _overallData['rentalIncome'] ?? 0,
                      Colors.green,
                    ),
                    if ((_overallData['securityDeposits'] ?? 0) > 0)
                      _buildDetailItem(
                        'Security Deposits',
                        _overallData['securityDeposits'] ?? 0,
                        Colors.lightGreen,
                      ),
                    if ((_overallData['otherIncome'] ?? 0) > 0)
                      _buildDetailItem(
                        'Other Income',
                        _overallData['otherIncome'] ?? 0,
                        Colors.teal,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Expense Details
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Divider(),
                    ..._buildExpenseCategories(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Charts
            _buildProfitLossChart(),
            SizedBox(height: 16),
            _buildExpensePieChart(),
            
          ] else
            Center(
              child: Text('No data available for selected month'),
            ),
        ],
      ),
    );
  }
  List<Widget> _buildExpenseCategories() {
    List<Widget> widgets = [];
    
    // Add known categories
    for (var category in expenseCategories) {
      final amount = _overallData['expenses_${category.toLowerCase().replaceAll(' ', '_')}'] ?? 0;
      if (amount > 0) {
        widgets.add(_buildDetailItem(
          category,
          amount,
          Colors.red[300]!,
        ));
      }
    }
    
    // Add Other expenses with notes
    final otherExpenses = _overallData['otherExpensesDetails'] as List<Map<String, dynamic>>? ?? [];
    if (otherExpenses.isNotEmpty) {
      widgets.add(Divider());
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Other Expenses',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      
      for (var expense in otherExpenses) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(expense['description'] ?? 'Unspecified'),
                ),
                Text(
                  '\$${expense['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.red[300],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildPropertyTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectMonth,
                        icon: Icon(Icons.calendar_today, size: 16),
                        label: Text('Change'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Consumer<PropertyProvider>(
                    builder: (context, propertyProvider, _) {
                      return DropdownButtonFormField<String>(
                        value: _selectedPropertyId,
                        decoration: InputDecoration(
                          labelText: 'Select Property',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Properties'),
                          ),
                          ...propertyProvider.properties.map((property) {
                            return DropdownMenuItem(
                              value: property.id,
                              child: Text(property.address),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPropertyId = value;
                          });
                          _loadReportData();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _selectedPropertyId == null
                  ? _buildPropertyComparisonChart()
                  : _buildSinglePropertyReport(),
        ),
      ],
    );
  }

  Widget _buildSinglePropertyReport() {
    if (_propertyData.isEmpty || !_propertyData.containsKey(_selectedPropertyId)) {
      return Center(child: Text('No data available for selected property'));
    }

    final data = _propertyData[_selectedPropertyId]!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Consumer<PropertyProvider>(
            builder: (context, provider, _) {
              final property = provider.properties
                  .firstWhere((p) => p.id == _selectedPropertyId,
                      orElse: () => Property(
                        id: '', 
                        userId: '', 
                        address: 'Unknown Property', 
                        propertyType: '', 
                        createdAt: DateTime.now()
                      ));
              
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(property.propertyType),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          
          // Summary card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Divider(),
                  _buildSummaryItem(
                    'Total Income',
                    data['totalIncome'] ?? 0,
                    Colors.green,
                  ),
                  Divider(),
                  _buildSummaryItem(
                    'Total Expenses',
                    data['totalExpenses'] ?? 0,
                    Colors.red,
                  ),
                  Divider(thickness: 2),
                  _buildSummaryItem(
                    'Net Profit/Loss',
                    data['netProfit'] ?? 0,
                    (data['netProfit'] ?? 0) > 0 ? Colors.green : Colors.red,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Income Details
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Divider(),
                  _buildDetailItem(
                    'Rental Income',
                    data['rentalIncome'] ?? 0,
                    Colors.green,
                  ),
                  if ((data['securityDeposits'] ?? 0) > 0)
                    _buildDetailItem(
                      'Security Deposits',
                      data['securityDeposits'] ?? 0,
                      Colors.lightGreen,
                    ),
                  if ((data['otherIncome'] ?? 0) > 0)
                    _buildDetailItem(
                      'Other Income',
                      data['otherIncome'] ?? 0,
                      Colors.teal,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Expense Details
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Divider(),
                  ..._buildPropertyExpenseCategories(data),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Charts
          _buildPropertyProfitLossChart(data),
          SizedBox(height: 16),
          _buildPropertyExpensePieChart(data),
        ],
      ),
    );
  }

  List<Widget> _buildPropertyExpenseCategories(Map<String, dynamic> data) {
    List<Widget> widgets = [];
    
    // Add known categories
    for (var category in expenseCategories) {
      final amount = data['expenses_${category.toLowerCase().replaceAll(' ', '_')}'] ?? 0;
      if (amount > 0) {
        widgets.add(_buildDetailItem(
          category,
          amount,
          Colors.red[300]!,
        ));
      }
    }
    
    // Add Other expenses with notes
    final otherExpenses = data['otherExpensesDetails'] as List<Map<String, dynamic>>? ?? [];
    if (otherExpenses.isNotEmpty) {
      widgets.add(Divider());
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Other Expenses',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      
      for (var expense in otherExpenses) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(expense['description'] ?? 'Unspecified'),
                ),
                Text(
                  '\$${expense['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.red[300],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildPropertyComparisonChart() {
    if (_propertyData.isEmpty) {
      return Center(child: Text('No data available for selected month'));
    }

    final sortedProperties = _propertyData.entries.toList()
      ..sort((a, b) => (b.value['netProfit'] ?? 0).compareTo(a.value['netProfit'] ?? 0));

    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Property Comparison',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _calculateMaxY(),
                            minY: _calculateMinY(),
                            barGroups: List.generate(sortedProperties.length, (index) {
                              final entry = sortedProperties[index];
                              final propertyId = entry.key;
                              final profit = entry.value['netProfit'] ?? 0;
                              
                              final property = propertyProvider.properties
                                  .firstWhere((p) => p.id == propertyId, 
                                            orElse: () => Property(
                                              id: propertyId, 
                                              userId: '', 
                                              address: 'Unknown', 
                                              propertyType: '', 
                                              createdAt: DateTime.now()
                                            ));
                              
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: profit,
                                    color: profit >= 0 ? Colors.green : Colors.red,
                                    width: 20,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(6),
                                      bottom: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text('\$${value.toInt()}');
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value.toInt() >= sortedProperties.length) {
                                      return Text('');
                                    }
                                    final propertyId = sortedProperties[value.toInt()].key;
                                    final property = propertyProvider.properties
                                        .firstWhere((p) => p.id == propertyId, 
                                                  orElse: () => Property(
                                                    id: propertyId, 
                                                    userId: '', 
                                                    address: 'Unknown', 
                                                    propertyType: '', 
                                                    createdAt: DateTime.now()
                                                  ));
                                    
                                    // Abbreviate property name to fit
                                    final shortName = property.address.split(' ').first;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        shortName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Properties Ranked by Profit/Loss',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              ...sortedProperties.map((entry) {
                final propertyId = entry.key;
                final data = entry.value;
                final netProfit = data['netProfit'] ?? 0;
                
                final property = propertyProvider.properties
                    .firstWhere((p) => p.id == propertyId, 
                              orElse: () => Property(
                                id: propertyId, 
                                userId: '', 
                                address: 'Unknown', 
                                propertyType: '', 
                                createdAt: DateTime.now()
                              ));
                
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(property.address),
                    subtitle: Text('Income: \$${(data['totalIncome'] ?? 0).toStringAsFixed(2)} • Expenses: \$${(data['totalExpenses'] ?? 0).toStringAsFixed(2)}'),
                    trailing: Text(
                      '\$${netProfit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedPropertyId = propertyId;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  double _calculateMaxY() {
    double maxProfit = 0;
    for (final data in _propertyData.values) {
      final profit = data['netProfit'] ?? 0;
      if (profit > maxProfit) maxProfit = profit;
    }
    return maxProfit * 1.2; // Add 20% padding
  }

  double _calculateMinY() {
    double minProfit = 0;
    for (final data in _propertyData.values) {
      final profit = data['netProfit'] ?? 0;
      if (profit < minProfit) minProfit = profit;
    }
    return minProfit * 1.2; // Add 20% padding
  }

  Widget _buildPropertyProfitLossChart(Map<String, dynamic> data) {
    return Container(
      height: 250,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Income vs Expenses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: data['totalIncome'] ?? 0,
                            color: Colors.green,
                            width: 22,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: data['totalExpenses'] ?? 0,
                            color: Colors.red,
                            width: 22,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: data['netProfit'] ?? 0,
                            color: (data['netProfit'] ?? 0) > 0 ? Colors.blue : Colors.purple,
                            width: 22,
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('\$${value.toInt()}');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final titles = ['Income', 'Expenses', 'Net'];
                            return Text(
                              titles[value.toInt()],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyExpensePieChart(Map<String, dynamic> data) {
    // Prepare data for pie chart
    List<PieChartSectionData> sections = [];
    double totalExpenses = data['totalExpenses'] ?? 0;
    
    if (totalExpenses > 0) {
      for (int i = 0; i < expenseCategories.length; i++) {
        final category = expenseCategories[i];
        final expenseKey = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
        final amount = data[expenseKey] ?? 0;
        
        if (amount > 0) {
          final percentage = (amount / totalExpenses) * 100;
          sections.add(
            PieChartSectionData(
              color: categoryColors[i % categoryColors.length],
              value: amount,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 50,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }
      }
    }
    
    if (sections.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(expenseCategories.length, (i) {
                            final category = expenseCategories[i];
                            final expenseKey = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
                            final amount = data[expenseKey] ?? 0;
                            
                            if (amount <= 0) {
                              return SizedBox.shrink();
                            }
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: categoryColors[i % categoryColors.length],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${amount.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitLossChart() {
    return Container(
      height: 250,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Income vs Expenses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: _overallData['totalIncome'] ?? 0,
                            color: Colors.green,
                            width: 30,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: _overallData['totalExpenses'] ?? 0,
                            color: Colors.red,
                            width: 30,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: _overallData['netProfit'] ?? 0,
                            color: (_overallData['netProfit'] ?? 0) > 0 ? Colors.blue : Colors.purple,
                            width: 30,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('\$${value.toInt()}');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final titles = ['Income', 'Expenses', 'Net'];
                            return Text(
                              titles[value.toInt()],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensePieChart() {
    // Prepare data for pie chart
    List<PieChartSectionData> sections = [];
    double totalExpenses = _overallData['totalExpenses'] ?? 0;
    
    if (totalExpenses > 0) {
      for (int i = 0; i < expenseCategories.length; i++) {
        final category = expenseCategories[i];
        final expenseKey = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
        final amount = _overallData[expenseKey] ?? 0;
        
        if (amount > 0) {
          final percentage = (amount / totalExpenses) * 100;
          sections.add(
            PieChartSectionData(
              color: categoryColors[i % categoryColors.length],
              value: amount,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 50,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }
      }
    }
    
    if (sections.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(expenseCategories.length, (i) {
                            final category = expenseCategories[i];
                            final expenseKey = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
                            final amount = _overallData[expenseKey] ?? 0;
                            
                            if (amount <= 0) {
                              return SizedBox.shrink();
                            }
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: categoryColors[i % categoryColors.length],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${amount.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            '\$${amount.toStringAsFixed(2)}',
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

  Widget _buildDetailItem(String label, double amount, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
            ),
          ),
        ],
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
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      // Ensure data providers are loaded
      await context.read<PaymentProvider>().loadAllPayments();
      await context.read<ExpenseProvider>().loadAllExpenses();
      await context.read<PropertyProvider>().loadProperties();
      await context.read<LeaseProvider>().loadAllLeases();
      
      // Calculate overall profit/loss
      await _calculateOverallProfitLoss();
      
      // Calculate property-specific profit/loss
      await _calculatePropertyProfitLoss();
      
    } catch (e) {
      print('Error loading report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading report: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateOverallProfitLoss() async {
    final Map<String, dynamic> overallData = {
      'totalIncome': 0.0,
      'rentalIncome': 0.0,
      'securityDeposits': 0.0,
      'otherIncome': 0.0,
      'totalExpenses': 0.0,
      'netProfit': 0.0,
      'otherExpensesDetails': <Map<String, dynamic>>[],
    };
    
    // Initialize expense categories
    for (var category in expenseCategories) {
      overallData['expenses_${category.toLowerCase().replaceAll(' ', '_')}'] = 0.0;
    }
    
    final payments = context.read<PaymentProvider>().payments;
    final expenses = context.read<ExpenseProvider>().expenses;
    final leases = context.read<LeaseProvider>().leases;
    
    // Calculate income
    for (var payment in payments.where((p) => 
        p.paymentDate.year == _selectedMonth.year &&
        p.paymentDate.month == _selectedMonth.month)) {
      
      // Find payment type (rent, security deposit, other)
      // Check payment notes for hints
      if (payment.notes != null && 
          payment.notes!.toLowerCase().contains('security deposit')) {
        overallData['securityDeposits'] += payment.amount;
      } else if (payment.notes != null && 
                !payment.notes!.toLowerCase().contains('rent')) {
        overallData['otherIncome'] += payment.amount;
      } else {
        // Default to rental income
        overallData['rentalIncome'] += payment.amount;
      }
      
      overallData['totalIncome'] += payment.amount;
    }
    
    // Calculate expenses
    for (var expense in expenses.where((e) => 
        e.expenseDate.year == _selectedMonth.year &&
        e.expenseDate.month == _selectedMonth.month)) {
      
      overallData['totalExpenses'] += expense.amount;
      
      // Categorize expenses
      final expenseType = expense.expenseType.toLowerCase();
      bool categorized = false;
      
      for (var category in expenseCategories) {
        if (expenseType == category.toLowerCase() || 
            expenseType.contains(category.toLowerCase())) {
          final key = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
          overallData[key] += expense.amount;
          categorized = true;
          break;
        }
      }
      
      // Handle "Other" expenses
      if (!categorized || expenseType == 'other') {
        final key = 'expenses_other';
        overallData[key] += expense.amount;
        
        // Add to other expenses details if description is available
        if (expense.description != null && expense.description!.isNotEmpty) {
          (overallData['otherExpensesDetails'] as List<Map<String, dynamic>>).add({
            'amount': expense.amount,
            'description': expense.description,
          });
        }
      }
    }
    
    // Calculate net profit/loss
    overallData['netProfit'] = overallData['totalIncome'] - overallData['totalExpenses'];
    
    setState(() {
      _overallData = overallData;
    });
  }

  Future<void> _calculatePropertyProfitLoss() async {
    final Map<String, Map<String, dynamic>> propertyData = {};
    final properties = context.read<PropertyProvider>().properties;
    final payments = context.read<PaymentProvider>().payments;
    final expenses = context.read<ExpenseProvider>().expenses;
    final leases = context.read<LeaseProvider>().leases;
    
    // Initialize data structure for each property
    for (var property in properties) {
      propertyData[property.id] = {
        'totalIncome': 0.0,
        'rentalIncome': 0.0,
        'securityDeposits': 0.0,
        'otherIncome': 0.0,
        'totalExpenses': 0.0,
        'netProfit': 0.0,
        'otherExpensesDetails': <Map<String, dynamic>>[],
      };
      
      // Initialize expense categories
      for (var category in expenseCategories) {
        propertyData[property.id]!['expenses_${category.toLowerCase().replaceAll(' ', '_')}'] = 0.0;
      }
    }
    
    // Calculate income for each property
    for (var payment in payments.where((p) => 
        p.paymentDate.year == _selectedMonth.year &&
        p.paymentDate.month == _selectedMonth.month)) {
      
      // Find which property this payment belongs to
      final matchingLeases = leases.where((l) => l.id == payment.leaseId).toList();
      
      if (matchingLeases.isNotEmpty) {
        final propertyId = matchingLeases.first.propertyId;
        if (propertyData.containsKey(propertyId)) {
          
          // Categorize payment
          if (payment.notes != null && 
              payment.notes!.toLowerCase().contains('security deposit')) {
            propertyData[propertyId]!['securityDeposits'] += payment.amount;
          } else if (payment.notes != null && 
                     !payment.notes!.toLowerCase().contains('rent')) {
            propertyData[propertyId]!['otherIncome'] += payment.amount;
          } else {
            // Default to rental income
            propertyData[propertyId]!['rentalIncome'] += payment.amount;
          }
          
          propertyData[propertyId]!['totalIncome'] += payment.amount;
        }
      }
    }
    
    // Calculate expenses for each property
    for (var expense in expenses.where((e) => 
        e.expenseDate.year == _selectedMonth.year &&
        e.expenseDate.month == _selectedMonth.month)) {
      
      final propertyId = expense.propertyId;
      if (propertyData.containsKey(propertyId)) {
        propertyData[propertyId]!['totalExpenses'] += expense.amount;
        
        // Categorize expenses
        final expenseType = expense.expenseType.toLowerCase();
        bool categorized = false;
        
        for (var category in expenseCategories) {
          if (expenseType == category.toLowerCase() || 
              expenseType.contains(category.toLowerCase())) {
            final key = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
            propertyData[propertyId]![key] += expense.amount;
            categorized = true;
            break;
          }
        }
        
        // Handle "Other" expenses
        if (!categorized || expenseType == 'other') {
          final key = 'expenses_other';
          propertyData[propertyId]![key] += expense.amount;
          
          // Add to other expenses details if description is available
          if (expense.description != null && expense.description!.isNotEmpty) {
            (propertyData[propertyId]!['otherExpensesDetails'] as List<Map<String, dynamic>>).add({
              'amount': expense.amount,
              'description': expense.description,
            });
          }
        }
      }
    }
    
    // Calculate profit for each property
    for (var entry in propertyData.entries) {
      final income = entry.value['totalIncome'] ?? 0;
      final expenses = entry.value['totalExpenses'] ?? 0;
      entry.value['netProfit'] = income - expenses;
    }
    
    setState(() {
      _propertyData = propertyData;
    });
  }
}