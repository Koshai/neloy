import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:property_management_app/providers/lease_provider.dart';
import 'package:property_management_app/providers/property_provider.dart';
import 'package:property_management_app/screens/properties/property_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/tenant.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/file_storage_service.dart';
import '../../providers/document_provider.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantDetailScreen({required this.tenant});

  @override
  _TenantDetailScreenState createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DocumentProvider>().loadTenantDocuments(widget.tenant.id);
      context.read<LeaseProvider>().loadLeasesByTenant(widget.tenant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tenant.firstName} ${widget.tenant.lastName}'),
      ),
      body: Column(
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

          // Add lease information to the screen
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
                          .firstOrNull;
                      
                      if (activeLease == null) {
                        return Text('No active lease');
                      }
                      
                      // Get property information
                      return Consumer<PropertyProvider>(
                        builder: (context, propertyProvider, _) {
                          final property = propertyProvider.properties
                              .where((p) => p.id == activeLease.propertyId)
                              .firstOrNull;
                          
                          if (property == null) return Text('Property not found');
                          
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.home),
                                title: Text(property.address),
                                subtitle: Text('${property.propertyType}'),
                                contentPadding: EdgeInsets.zero,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PropertyDetailScreen(property: property),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.calendar_today),
                                title: Text('Lease Period'),
                                subtitle: Text(
                                  '${DateFormat('MMM dd, yyyy').format(activeLease.startDate)} - ${DateFormat('MMM dd, yyyy').format(activeLease.endDate)}'
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              ListTile(
                                leading: Icon(Icons.attach_money),
                                title: Text('Monthly Rent'),
                                subtitle: Text('\$${activeLease.rentAmount.toStringAsFixed(2)}'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (activeLease.securityDeposit != null)
                                ListTile(
                                  leading: Icon(Icons.account_balance_wallet),
                                  title: Text('Security Deposit'),
                                  subtitle: Text('\$${activeLease.securityDeposit!.toStringAsFixed(2)}'),
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
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Implement document viewing
                        },
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
  // For image documents
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
    
    // Upload to Supabase Storage
    final path = await _uploadToSupabase(imageFile);
    
    // Save document reference to database
    await context.read<DocumentProvider>().addDocument(
      tenantId: widget.tenant.id,
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

Future<String> _uploadToSupabase(File file) async {
  final bytes = await file.readAsBytes();
  final fileExt = file.path.split('.').last;
  final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
  final filePath = '${widget.tenant.id}/$fileName';
  
  await Supabase.instance.client.storage
      .from('tenant-documents')
      .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileExt),
        ),
      );
      
  return filePath;
}

String _getContentType(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    default:
      return 'application/octet-stream';
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