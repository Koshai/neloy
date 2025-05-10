import 'package:flutter/material.dart';
import 'package:property_management_app/providers/subscription_provider.dart';
import 'package:property_management_app/screens/tenants/add_tenant_with_lease_screen.dart';
import 'package:property_management_app/widgets/limit_warning_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/tenant_provider.dart';
import 'add_edit_tenant_screen.dart';
import 'tenant_detail_screen.dart';

class TenantListScreen extends StatefulWidget {
  @override
  _TenantListScreenState createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<TenantProvider>().loadTenants()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              final subscriptionProvider = context.read<SubscriptionProvider>();
              if (subscriptionProvider.canAddTenant) {
                // Show dialog to choose between adding just a tenant or with lease
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Add Tenant'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.person_add),
                          title: Text('Add Tenant Only'),
                          subtitle: Text('Create tenant without assigning to a property'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddEditTenantScreen()),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.home),
                          title: Text('Add Tenant with Lease'),
                          subtitle: Text('Create tenant and assign to a property'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddTenantWithLeaseScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => LimitWarningDialog(limitType: 'tenant'),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<TenantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.tenants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tenants yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to add a tenant', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.tenants.length,
            itemBuilder: (context, index) {
              final tenant = provider.tenants[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${tenant.firstName[0]}${tenant.lastName[0]}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text('${tenant.firstName} ${tenant.lastName}'),
                  subtitle: Text(tenant.email ?? 'No email'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantDetailScreen(tenant: tenant),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}