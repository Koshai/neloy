import 'package:flutter/material.dart';
import '../models/document.dart';
import '../services/database_service.dart';

class DocumentProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  List<Document> _documents = [];
  bool _isLoading = false;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;

  Future<void> loadTenantDocuments(String tenantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _databaseService.getTenantDocuments(tenantId);
    } catch (e) {
      print('Error loading documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDocument({
    required String tenantId,
    required String documentType,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final document = await _databaseService.addDocument(
        tenantId: tenantId,
        documentType: documentType,
        filePath: filePath,
        fileName: fileName,
      );
      _documents.add(document);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}