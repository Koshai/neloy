class Expense {
  final String id;
  final String propertyId;
  final String expenseType;
  final double amount;
  final DateTime expenseDate;
  final String? description;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.propertyId,
    required this.expenseType,
    required this.amount,
    required this.expenseDate,
    this.description,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      propertyId: json['property_id'],
      expenseType: json['expense_type'],
      amount: json['amount'].toDouble(),
      expenseDate: DateTime.parse(json['expense_date']),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'expense_type': expenseType,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'description': description,
    };
  }
}