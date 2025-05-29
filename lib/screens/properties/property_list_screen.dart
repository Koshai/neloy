import 'package:flutter/material.dart';
import 'package:ghor/providers/subscription_provider.dart';
import 'package:ghor/widgets/limit_warning_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import 'add_edit_property_screen.dart';
import 'property_detail_screen.dart';

class PropertyListScreen extends StatefulWidget {
  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<PropertyProvider>().loadProperties()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Properties'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              final subscriptionProvider = context.read<SubscriptionProvider>();
                if (subscriptionProvider.canAddProperty){
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditPropertyScreen()),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => LimitWarningDialog(limitType: 'property'),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No properties yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to add a property', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.properties.length,
            itemBuilder: (context, index) {
              final property = provider.properties[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.home),
                  ),
                  title: Text(property.address),
                  subtitle: Text(property.propertyType),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(property: property),
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