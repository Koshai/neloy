class Tenant {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
  }
}