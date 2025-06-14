import 'package:flutter/material.dart';
import 'package:ghor/providers/subscription_provider.dart';
import 'package:ghor/screens/tenants/add_edit_tenant_screen.dart';
import 'package:ghor/services/database_service.dart';
import 'package:ghor/utils/data_sync_manager.dart';
import 'package:ghor/widgets/limit_warning_dialog.dart';
import 'package:provider/provider.dart';
import '../../models/tenant.dart';
import '../../models/lease.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/file_storage_service.dart';
import '../../providers/document_provider.dart';
import '../../providers/lease_provider.dart';
import '../../providers/property_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantDetailScreen({required this.tenant});

  @override
  _TenantDetailScreenState createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  bool _isLoading = true;
  final _fileStorageService = FileStorageService();

  @override
  void initState() {
    super.initState();
    // First ensure full sync to avoid data inconsistencies
    _fullSyncAndLoadData();
  }

  Future<void> _fullSyncAndLoadData() async {
    setState(() => _isLoading = true);
    
    try {
      // First do a full data sync to ensure consistency across the app
      await DataSyncService().syncAll(context);
      
      // Then load tenant-specific data
      await _loadTenantData();
    } catch (e) {
      print('Error loading tenant data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tenant data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTenantData() async {
    try {
      // Load both documents and leases
      await context.read<DocumentProvider>().loadTenantDocuments(widget.tenant.id);
      await context.read<LeaseProvider>().loadLeasesByTenant(widget.tenant.id);
      await context.read<PropertyProvider>().loadProperties();
    } catch (e) {
      print('Error loading tenant-specific data: $e');
    }
  }

  void _confirmDeleteTenant(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Tenant'),
        content: Text(
          'Are you sure you want to delete this tenant? This will also delete all associated leases, payments, and documents stored on your device. This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog
                
                // Delete local files first
                final documents = context.read<DocumentProvider>().documents;
                for (final doc in documents) {
                  await _fileStorageService.deleteFile(
                    bucket: 'tenant-documents',
                    path: doc.filePath,
                  );
                }
                
                await DatabaseService().deleteTenant(widget.tenant.id);
                // Sync all data after deletion
                await DataSyncService().syncAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tenant deleted successfully')),
                );
                Navigator.pop(context); // Go back to tenant list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting tenant: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tenant.firstName} ${widget.tenant.lastName}'),
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fullSyncAndLoadData,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTenantScreen(tenant: widget.tenant),
                ),
              ).then((_) {
                // Refresh data when returning from edit screen
                _fullSyncAndLoadData();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeleteTenant(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tenant Info Card
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          if (widget.tenant.email != null)
                            ListTile(
                              leading: Icon(Icons.email),
                              title: Text(widget.tenant.email!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          if (widget.tenant.phone != null)
                            ListTile(
                              leading: Icon(Icons.phone),
                              title: Text(widget.tenant.phone!),
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Lease Information section
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lease Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          Consumer<LeaseProvider>(
                            builder: (context, leaseProvider, _) {
                              if (leaseProvider.isLoading) {
                                return Center(child: CircularProgressIndicator());
                              }
                              
                              // Find active lease for this tenant
                              final activeLease = leaseProvider.leases
                                  .where((lease) => 
                                    lease.tenantId == widget.tenant.id && 
                                    lease.status == 'active')
                                  .toList();
                              
                              if (activeLease.isEmpty) {
                                return Text('No active lease');
                              }
                              
                              final lease = activeLease.first;
                              
                              // Get property information
                              return Consumer<PropertyProvider>(
                                builder: (context, propertyProvider, _) {
                                  final property = propertyProvider.properties
                                      .where((p) => p.id == lease.propertyId)
                                      .toList();
                                  
                                  if (property.isEmpty) return Text('Property not found');
                                  
                                  return Column(
                                    children: [
                                      ListTile(
                                        leading: Icon(Icons.home),
                                        title: Text(property.first.address),
                                        subtitle: Text('${property.first.propertyType}'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.calendar_today),
                                        title: Text('Lease Period'),
                                        subtitle: Text(
                                          '${DateFormat('MMM dd, yyyy').format(lease.startDate)} - ${DateFormat('MMM dd, yyyy').format(lease.endDate)}'
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.attach_money),
                                        title: Text('Monthly Rent'),
                                        subtitle: Text('\$${lease.rentAmount.toStringAsFixed(2)}'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      if (lease.securityDeposit != null)
                                        ListTile(
                                          leading: Icon(Icons.account_balance_wallet),
                                          title: Text('Security Deposit'),
                                          subtitle: Text('\$${lease.securityDeposit!.toStringAsFixed(2)}'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Documents Section
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Documents (Local Storage)',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              ElevatedButton.icon(
                                onPressed: _uploadDocument,
                                icon: Icon(Icons.upload),
                                label: Text('Upload'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          
                          // Local storage info
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.security, color: Colors.green[600], size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Documents are encrypted and stored securely on your device',
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
                          
                          // Documents List
                          Consumer<DocumentProvider>(
                            builder: (context, provider, _) {
                              if (provider.isLoading) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (provider.documents.isEmpty) {
                                return Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.folder_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No documents uploaded yet',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return SizedBox(
                                height: 300, // Fixed height for documents section
                                child: ListView.builder(
                                  itemCount: provider.documents.length,
                                  itemBuilder: (context, index) {
                                    final document = provider.documents[index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Icon(_getDocumentIcon(document.documentType)),
                                        title: Text(document.fileName),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Type: ${document.documentType}'),
                                            Text(
                                              'Stored locally',
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _uploadDocument() async {
    // Check if user can add more documents
    if (!context.read<SubscriptionProvider>().canAddDocument) {
      showDialog(
        context: context,
        builder: (_) => LimitWarningDialog(limitType: 'document'),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    
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
      
      // Show progress dialog
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
      
      // Get the file extension for document type
      final String fileExt = file.path.split('.').last.toLowerCase();
      
      // Save to local storage (encrypted)
      final path = await _fileStorageService.uploadFile(
        file: imageFile,
        bucket: 'tenant-documents',
        folder: widget.tenant.id,
      );
      
      // Save document reference to database
      await context.read<DocumentProvider>().addDocument(
        tenantId: widget.tenant.id,
        propertyId: null,
        documentType: fileExt,
        filePath: path,
        fileName: file.name,
      );

      // Sync all data after document upload
      await DataSyncService().syncAll(context);

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
    }
  }

  Future<void> _viewDocument(dynamic document) async {
    try {
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
        bucket: 'tenant-documents',
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
    }
  }

  Future<void> _confirmDeleteDocument(dynamic document) async {
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
              'This will permanently remove the encrypted file from your device.',
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
          bucket: 'tenant-documents',
          path: document.filePath,
        );
        
        // Delete from database
        await context.read<DocumentProvider>().deleteDocument(document.id);
        
        // Sync all data after document deletion
        await DataSyncService().syncAll(context);

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

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}