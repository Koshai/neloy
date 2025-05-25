class AppConstants {
  static const String supabaseUrl = 'https://enxmmalzlpmjphitonyx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVueG1tYWx6bHBtanBoaXRvbnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNjU5NzYsImV4cCI6MjA2MTk0MTk3Nn0.DPhJmPz67GNWjtv0m6t_tfo7rhgHFUym1vB75rTdvOY';
  static const String appScheme = 'propertymanagerapp';
  static const String backendUrl = 'https://enxmmalzlpmjphitonyx.supabase.co/functions/v1';

  // Mobile Payment Configuration
  static const Map<String, String> applePay = {
    'merchantId': 'merchant.com.yourapp.propertypro',
    'merchantName': 'PropertyPro',
  };
  
  static const Map<String, String> googlePay = {
    'merchantId': 'BCR2DN6TZMIPYPC4',
    'merchantName': 'PropertyPro',
  };

  // Property Types
  static const List<String> propertyTypes = [
    'House',
    'Apartment',
    'Condo',
    'Townhouse',
    'Duplex',
    'Commercial',
    'Other'
  ];
  
  // Expense Types
  static const List<String> expenseTypes = [
    'Maintenance',
    'Repair',
    'Utilities',
    'Property Tax',
    'Insurance',
    'Mortgage',
    'Management Fee',
    'Other'
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Check',
    'Bank Transfer',
    'Credit Card',
    'Online Payment',
    'Other'
  ];
  
  // Lease Status
  static const List<String> leaseStatus = [
    'Active',
    'Expired',
    'Terminated',
    'Pending'
  ];

  // In-App Purchase Product IDs
  static const Map<String, Map<String, dynamic>> products = {
    'premium_monthly': {
      'id_ios': 'com.yourapp.propertymanagement.premium.monthly',
      'id_android': 'premium_monthly',
      'title': 'Premium Monthly',
      'price': 4.99,
    },
    'premium_yearly': {
      'id_ios': 'com.yourapp.propertymanagement.premium.yearly',
      'id_android': 'premium_yearly', 
      'title': 'Premium Yearly',
      'price': 49.99,
    },
  };
}