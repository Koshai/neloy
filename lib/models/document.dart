class Document {
  final String id;
  final String userId;
  final String? tenantId;
  final String? propertyId;
  final String documentType;
  final String filePath;
  final String fileName;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.userId,
    this.tenantId,
    this.propertyId,
    required this.documentType,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      userId: json['user_id'],
      tenantId: json['tenant_id'],
      propertyId: json['property_id'],
      documentType: json['document_type'],
      filePath: json['file_path'],
      fileName: json['file_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tenant_id': tenantId,
      'property_id': propertyId,
      'document_type': documentType,
      'file_path': filePath,
      'file_name': fileName,
    };
  }
}