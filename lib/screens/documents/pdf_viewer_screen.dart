import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';

class PDFViewerScreen extends StatefulWidget {
  final File file;
  final String documentName;

  const PDFViewerScreen({
    required this.file,
    required this.documentName,
  });

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PdfController pdfController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // The file is already decrypted at this point
      pdfController = PdfController(
        document: PdfDocument.openFile(widget.file.path),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading PDF: $e';
      });
    }
  }

  @override
  void dispose() {
    pdfController.dispose();
    // Delete the temporary decrypted file when done
    try {
      widget.file.deleteSync();
    } catch (e) {
      print('Error deleting temporary file: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentName),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : PdfView(
                  controller: pdfController,
                ),
    );
  }
}