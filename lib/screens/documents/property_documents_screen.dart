import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../services/file_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'pdf_viewer_screen.dart';
import 'package:open_file/open_file.dart';

class PropertyDocumentsScreen extends StatefulWidget {
  final Property property;

  const PropertyDocumentsScreen({required this.property});

  @override
  _PropertyDocumentsScreenState createState() => _PropertyDocumentsScreenState();
}

class _PropertyDocumentsScreenState extends State<PropertyDocumentsScreen> {
  bool _isLoading = false;
  final _fileStorageService = FileStorageService();

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
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showStorageInfo,
            tooltip: 'Storage Information',
          ),
        ],
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
          
          // Storage Info Banner
          _buildStorageInfoBanner(),
          
          // Documents Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents (Stored Locally)',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No documents uploaded yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Documents are stored securely on your device',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.documents.length,
                  itemBuilder: (context, index) {
                    final document = provider.documents[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(_getDocumentIcon(document.documentType)),
                        title: Text(document.fileName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${document.documentType}'),
                            Text(
                              'Added: ${_formatDate(document.createdAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              'Stored locally on device',
                              style: TextStyle(
                                fontSize: 11, 
                                color: Colors.green[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                _viewDocument(document);
                                break;
                              case 'delete':
                                _confirmDeleteDocument(document);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility),
                                  SizedBox(width: 8),
                                  Text('View'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildStorageInfoBanner() {
    return FutureBuilder<int>(
      future: _fileStorageService.getTotalStorageUsed(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final usedMB = (snapshot.data! / (1024 * 1024)).toStringAsFixed(1);
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.storage, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local storage used: ${usedMB} MB • Files are encrypted and stored on your device',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.green[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Files are encrypted and stored locally on your device',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
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
    setState(() => _isLoading = true);
    
    try {
      // Convert to File
      final File imageFile = File(file.path);
      
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Encrypting and saving document...'),
            ],
          ),
        ),
      );
      
      // Save to local storage (encrypted)
      final path = await _fileStorageService.uploadFile(
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

      // Close progress dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document uploaded and encrypted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close progress dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDocument(Document document) async {
    try {
      setState(() => _isLoading = true);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Decrypting document...'),
            ],
          ),
        ),
      );
      
      final file = await _fileStorageService.downloadFile(
        bucket: 'property-documents',
        path: document.filePath,
      );
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (file != null) {
        // Use open_file package to open the decrypted file
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decrypt the document')),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete "${document.fileName}"?'),
            SizedBox(height: 8),
            Text(
              'This will permanently remove the file from your device.',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from local storage
        await _fileStorageService.deleteFile(
          bucket: 'property-documents',
          path: document.filePath,
        );
        
        // Delete from database
        await context.read<DocumentProvider>().deleteDocument(document.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document: $e')),
        );
      }
    }
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Storage Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔐 Security:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Files are encrypted using AES-256 encryption'),
            Text('• Encryption keys are stored securely on your device'),
            SizedBox(height: 12),
            Text('📱 Local Storage:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Documents are stored on your device only'),
            Text('• No files are uploaded to cloud servers'),
            Text('• Files remain private and under your control'),
            SizedBox(height: 12),
            FutureBuilder<int>(
              future: _fileStorageService.getTotalStorageUsed(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final usedMB = (snapshot.data! / (1024 * 1024)).toStringAsFixed(1);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💾 Storage Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('• Total used: ${usedMB} MB'),
                      Text('• Location: Device internal storage'),
                    ],
                  );
                }
                return Text('💾 Calculating storage usage...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _fileStorageService.cleanupTempFiles();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Temporary files cleaned up')),
              );
            },
            child: Text('Clean Temp Files'),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}