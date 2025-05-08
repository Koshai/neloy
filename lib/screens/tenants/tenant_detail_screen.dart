import 'package:flutter/material.dart';
import 'package:property_management_app/providers/subscription_provider.dart';
import 'package:property_management_app/widgets/limit_warning_dialog.dart';
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
import 'package:open_file/open_file.dart';  // Add this import

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantDetailScreen({required this.tenant});

  @override
  _TenantDetailScreenState createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      // Load both documents and leases
      await context.read<DocumentProvider>().loadTenantDocuments(widget.tenant.id);
      await context.read<LeaseProvider>().loadLeasesByTenant(widget.tenant.id);
      await context.read<PropertyProvider>().loadProperties();
    } catch (e) {
      print('Error loading tenant data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tenant.firstName} ${widget.tenant.lastName}'),
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
                  
                  // Lease Information
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
                          SizedBox(height: 16),
                          
                          // Documents List
                          Consumer<DocumentProvider>(
                            builder: (context, provider, _) {
                              if (provider.isLoading) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (provider.documents.isEmpty) {
                                return Center(
                                  child: Text('No documents uploaded yet'),
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
                                        subtitle: Text(document.documentType),
                                        trailing: IconButton(
                                          icon: Icon(Icons.remove_red_eye),
                                          onPressed: () => _viewDocument(document),
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
      
      // Get the file extension for document type
      final String fileExt = file.path.split('.').last.toLowerCase();
      
      // Upload to Supabase Storage
      final path = await FileStorageService().uploadFile(
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    }
  }

  Future<void> _viewDocument(dynamic document) async {
    try {
      final file = await FileStorageService().downloadFile(
        bucket: 'tenant-documents',
        path: document.filePath,
      );
      
      if (file != null) {
        // Use the device's default app to open the file
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result.message}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
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