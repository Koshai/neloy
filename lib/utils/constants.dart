class AppConstants {
  static const String supabaseUrl = 'https://enxmmalzlpmjphitonyx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVueG1tYWx6bHBtanBoaXRvbnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNjU5NzYsImV4cCI6MjA2MTk0MTk3Nn0.DPhJmPz67GNWjtv0m6t_tfo7rhgHFUym1vB75rTdvOY';
  
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
}