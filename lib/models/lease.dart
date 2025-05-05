class Lease {
  final String id;
  final String propertyId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final double rentAmount;
  final double? securityDeposit;
  final String status;
  final DateTime createdAt;

  Lease({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    this.securityDeposit,
    required this.status,
    required this.createdAt,
  });

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'],
      propertyId: json['property_id'],
      tenantId: json['tenant_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      rentAmount: json['rent_amount'].toDouble(),
      securityDeposit: json['security_deposit']?.toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'tenant_id': tenantId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'rent_amount': rentAmount,
      'security_deposit': securityDeposit,
      'status': status,
    };
  }
}