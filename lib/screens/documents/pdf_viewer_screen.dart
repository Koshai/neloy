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

  @override
  void initState() {
    super.initState();
    pdfController = PdfController(
      document: PdfDocument.openFile(widget.file.path),
    );
  }

  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentName),
      ),
      body: PdfView(
        controller: pdfController,
      ),
    );
  }
}