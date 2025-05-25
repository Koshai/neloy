import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../services/file_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'pdf_viewer_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';

class PropertyDocumentsScreen extends StatefulWidget {
  final Property property;

  const PropertyDocumentsScreen({required this.property});

  @override
  _PropertyDocumentsScreenState createState() => _PropertyDocumentsScreenState();
}

class _PropertyDocumentsScreenState extends State<PropertyDocumentsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<DocumentProvider>().loadPropertyDocuments(widget.property.id)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Documents'),
      ),
      body: Column(
        children: [
          // Property Info
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.home, size: 40, color: Colors.blue),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.property.address,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(widget.property.propertyType),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Documents Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _uploadDocument,
                  icon: Icon(Icons.upload),
                  label: Text('Upload'),
                ),
              ],
            ),
          ),
          
          // Documents List
          Consumer<DocumentProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (provider.documents.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Text('No documents uploaded yet'),
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: provider.documents.length,
                  itemBuilder: (context, index) {
                    final document = provider.documents[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(_getDocumentIcon(document.documentType)),
                        title: Text(document.fileName),
                        subtitle: Text(document.documentType),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteDocument(document.id),
                        ),
                        onTap: () => _viewDocument(document),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument() async {
    // Show dialog to choose between camera and gallery
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _handleUpload(image);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    _handleUpload(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleUpload(XFile file) async {
    try {
      // Convert to File
      final File imageFile = File(file.path);
      
      // Upload to Supabase Storage
      final path = await FileStorageService().uploadFile(
        file: imageFile,
        bucket: 'property-documents',
        folder: widget.property.id,
      );
      
      // Save document reference to database
      await context.read<DocumentProvider>().addDocument(
        propertyId: widget.property.id,
        tenantId: null,
        documentType: file.path.split('.').last,
        filePath: path,
        fileName: file.name,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    }
  }

  Future<void> _viewDocument(Document document) async {
    try {
      // Show loading indicator
      setState(() => _isLoading = true);
      
      final file = await FileStorageService().downloadFile(
        bucket: 'property-documents',
        path: document.filePath,
      );
      
      if (file != null) {
        // Hide loading indicator
        setState(() => _isLoading = false);
        
        // Use open_file package to open the decrypted file
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result.message}')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decrypt the document')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await context.read<DocumentProvider>().deleteDocument(documentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}