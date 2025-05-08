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

  // Add this method
  Future<void> loadPropertyDocuments(String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _databaseService.getPropertyDocuments(propertyId);
    } catch (e) {
      print('Error loading property documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDocument({
    String? tenantId,
    String? propertyId,
    required String documentType,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final document = await _databaseService.addDocument(
        tenantId: tenantId,
        propertyId: propertyId,
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

  // Add this method
  Future<void> deleteDocument(String documentId) async {
    try {
      await _databaseService.deleteDocument(documentId);
      _documents.removeWhere((doc) => doc.id == documentId);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}