import 'package:flutter/material.dart';
import 'package:property_management_app/services/lease_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/payment_provider.dart';
import '../properties/property_list_screen.dart';
import '../tenants/tenant_list_screen.dart';
import '../payments/payment_list_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../reports/profit_loss_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndUpdateLeases();
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
        ],
      ),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Management Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Padding(
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
                  DashboardCard(
                    title: 'Monthly Income',
                    value: '\$5,200',
                    icon: Icons.attach_money,
                    color: Colors.orange,
                  ),
                  DashboardCard(
                    title: 'Monthly Expenses',
                    value: '\$2,800',
                    icon: Icons.trending_up,
                    color: Colors.red,
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