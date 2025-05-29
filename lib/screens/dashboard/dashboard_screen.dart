import 'package:flutter/material.dart';
import 'package:ghor/providers/lease_provider.dart';
import 'package:ghor/providers/subscription_provider.dart';
import 'package:ghor/screens/calendar/calendar_screen.dart';
import 'package:ghor/screens/subscription/subscription_screen.dart';
import 'package:ghor/services/lease_service.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/expense_provider.dart';
import '../properties/property_list_screen.dart';
import '../tenants/tenant_list_screen.dart';
import '../payments/payment_list_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../reports/profit_loss_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _checkAndUpdateLeases();

    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Perform full data sync
      await DataSyncService().syncAll(context);
    } catch (e) {
      print('DASHBOARD: Error in initial data sync: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndUpdateLeases() async {
    try {
      final leaseService = LeaseService();
      await leaseService.archiveExpiredLeases();
      // Refresh providers if needed
      context.read<PropertyProvider>().loadProperties();
      context.read<TenantProvider>().loadTenants();
    } catch (e) {
      print('Error checking expired leases: $e');
    }
  }
  
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardHomeScreen(),
    PropertyListScreen(),
    TenantListScreen(),
    PaymentListScreen(),
    ExpenseListScreen(),
    ProfitLossScreen(),
    CalendarScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Tenants'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        ],
      ),
    );
  }
}

class DashboardHomeScreen extends StatefulWidget {
  @override
  _DashboardHomeScreenState createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load all the data needed for the dashboard
      await context.read<PropertyProvider>().loadProperties();
      await context.read<TenantProvider>().loadTenants();
      await context.read<PaymentProvider>().loadAllPayments();
      await context.read<ExpenseProvider>().loadAllExpenses();
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Management Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.card_membership),
            tooltip: 'Subscription',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubscriptionScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sync All Data',
            onPressed: () async {
              // Show syncing indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Syncing data...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Perform full sync
              await DataSyncService().syncAll(context);
              
              // Update UI
              setState(() {});
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data synchronized successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        Consumer<PropertyProvider>(
                          builder: (context, provider, _) => DashboardCard(
                            title: 'Total Properties',
                            value: provider.properties.length.toString(),
                            icon: Icons.home,
                            color: Colors.blue,
                          ),
                        ),
                        Consumer<TenantProvider>(
                          builder: (context, provider, _) => DashboardCard(
                            title: 'Active Tenants',
                            value: provider.tenants.length.toString(),
                            icon: Icons.people,
                            color: Colors.green,
                          ),
                        ),
                        Consumer<PaymentProvider>(
                          builder: (context, provider, _) {
                            // Calculate monthly income
                            final now = DateTime.now();
                            final monthlyPayments = provider.payments
                                .where((payment) => 
                                  payment.paymentDate.year == now.year &&
                                  payment.paymentDate.month == now.month)
                                .toList();
                            
                            double total = 0;
                            for (var payment in monthlyPayments) {
                              total += payment.amount;
                            }
                            
                            final formatter = NumberFormat('#,##0.00', 'en_US');
                            
                            return DashboardCard(
                              title: 'Monthly Income',
                              value: '\$${formatter.format(total)}',
                              icon: Icons.attach_money,
                              color: Colors.orange,
                            );
                          },
                        ),
                        Consumer<ExpenseProvider>(
                          builder: (context, provider, _) {
                            // Calculate monthly expenses
                            final now = DateTime.now();
                            final monthlyExpenses = provider.expenses
                                .where((expense) => 
                                  expense.expenseDate.year == now.year &&
                                  expense.expenseDate.month == now.month)
                                .toList();
                            
                            double total = 0;
                            for (var expense in monthlyExpenses) {
                              total += expense.amount;
                            }
                            
                            final formatter = NumberFormat('#,##0.00', 'en_US');
                            
                            return DashboardCard(
                              title: 'Monthly Expenses',
                              value: '\$${formatter.format(total)}',
                              icon: Icons.trending_up,
                              color: Colors.red,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: color),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumUpsellBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        // Don't show for premium users
        if (provider.isPremium) {
          return SizedBox.shrink();
        }
        
        // Calculate usage percentages
        final propertyUsage = provider.propertyCount / provider.propertyLimit;
        final tenantUsage = provider.tenantCount / provider.tenantLimit;
        final documentUsage = provider.documentCount / provider.documentLimit;
        
        // Determine which resource is closest to limit
        String message = '';
        double highestUsage = 0;
        
        if (propertyUsage > highestUsage) {
          highestUsage = propertyUsage;
          message = 'properties';
        }
        
        if (tenantUsage > highestUsage) {
          highestUsage = tenantUsage;
          message = 'tenants';
        }
        
        if (documentUsage > highestUsage) {
          highestUsage = documentUsage;
          message = 'documents';
        }
        
        // Customize message based on usage
        String callToAction = '';
        Color bannerColor = Colors.blue[50]!;
        
        if (highestUsage >= 1.0) {
          callToAction = 'You\'ve reached your free plan limit for $message';
          bannerColor = Colors.orange[50]!;
        } else if (highestUsage >= 0.8) {
          callToAction = 'You\'re approaching your free plan limit for $message';
          bannerColor = Colors.amber[50]!;
        } else {
          callToAction = 'Enjoying PropertyPro? Upgrade for unlimited $message';
        }
        
        return Card(
          margin: EdgeInsets.all(16),
          color: bannerColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: bannerColor == Colors.orange[50]! 
                  ? Colors.orange[300]! 
                  : Colors.blue[200]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      bannerColor == Colors.orange[50]! 
                          ? Icons.warning_amber 
                          : Icons.star,
                      color: bannerColor == Colors.orange[50]! 
                          ? Colors.orange 
                          : Colors.amber,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        callToAction,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildUsageIndicator(
                  context,
                  title: 'Properties',
                  current: provider.propertyCount,
                  max: provider.propertyLimit,
                ),
                SizedBox(height: 8),
                _buildUsageIndicator(
                  context,
                  title: 'Tenants',
                  current: provider.tenantCount,
                  max: provider.tenantLimit,
                ),
                SizedBox(height: 8),
                _buildUsageIndicator(
                  context,
                  title: 'Documents',
                  current: provider.documentCount,
                  max: provider.documentLimit,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SubscriptionScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: Text('View Premium Plans'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUsageIndicator(
    BuildContext context, {
    required String title,
    required int current,
    required int max,
  }) {
    final percentage = (current / max).clamp(0.0, 1.0);
    final isAtLimit = current >= max;
    final isApproachingLimit = percentage >= 0.8;
    
    return Row(
      children: [
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isAtLimit 
                  ? Colors.red 
                  : (isApproachingLimit ? Colors.orange : Colors.blue),
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$current/$max',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isAtLimit 
                ? Colors.red 
                : (isApproachingLimit ? Colors.orange : null),
          ),
        ),
      ],
    );
  }
}