// lib/services/pdf_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:property_management_app/models/lease.dart';
import 'package:property_management_app/models/payment.dart';
import 'package:property_management_app/models/tenant.dart';
import 'package:share_plus/share_plus.dart';
import '../models/property.dart';

class PdfService {
  // Generate a profit and loss statement PDF for overall finances
  Future<File> generateOverallProfitLossPdf({
    required DateTime reportPeriod,
    required Map<String, dynamic> overallData,
    required String username,
  }) async {
    // Load font
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    // Create PDF document
    final pdf = pw.Document();

    // Format currency values
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormatter = DateFormat('MMMM yyyy');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(
          reportTitle: 'Profit & Loss Statement',
          reportPeriod: dateFormatter.format(reportPeriod),
          companyName: username,
          font: ttf,
          boldFont: boldTtf,
        ),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          // Summary Section
          _buildSummarySection(
            overallData: overallData,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
          
          pw.SizedBox(height: 20),
          
          // Income Details Section
          _buildIncomeDetailsSection(
            overallData: overallData,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
          
          pw.SizedBox(height: 20),
          
          // Expense Details Section
          _buildExpenseDetailsSection(
            overallData: overallData,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
        ],
      ),
    );

    // Save the PDF document
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/profit_loss_statement_${DateFormat('yyyy_MM').format(reportPeriod)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Generate a profit and loss statement PDF for a specific property
  Future<File> generatePropertyProfitLossPdf({
    required DateTime reportPeriod,
    required Map<String, dynamic> propertyData,
    required Property property,
    required String username,
  }) async {
    // Load font
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    // Create PDF document
    final pdf = pw.Document();

    // Format currency values
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormatter = DateFormat('MMMM yyyy');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(
          reportTitle: 'Property Profit & Loss Statement',
          reportPeriod: dateFormatter.format(reportPeriod),
          companyName: username,
          propertyName: property.address,
          font: ttf,
          boldFont: boldTtf,
        ),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          // Property Info Section
          _buildPropertyInfoSection(
            property: property,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
          
          pw.SizedBox(height: 20),
          
          // Summary Section
          _buildSummarySection(
            overallData: propertyData,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
          
          pw.SizedBox(height: 20),
          
          // Income Details Section
          _buildIncomeDetailsSection(
            overallData: propertyData,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
          
          pw.SizedBox(height: 20),
          
          // Expense Details Section
          _buildExpenseDetailsSection(
            overallData: propertyData,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
        ],
      ),
    );

    // Save the PDF document
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/property_profit_loss_${property.address.replaceAll(' ', '_')}_${DateFormat('yyyy_MM').format(reportPeriod)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Generate a comparison PDF for multiple properties
  Future<File> generatePropertyComparisonPdf({
    required DateTime reportPeriod,
    required Map<String, Map<String, dynamic>> propertiesData,
    required List<Property> properties,
    required String username,
  }) async {
    // Load font
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    // Create PDF document
    final pdf = pw.Document();

    // Format currency values
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormatter = DateFormat('MMMM yyyy');
    
    // Sort properties by profitability
    final sortedPropertiesData = propertiesData.entries.toList()
      ..sort((a, b) => 
        (b.value['netProfit'] ?? 0).compareTo(a.value['netProfit'] ?? 0));
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(
          reportTitle: 'Property Comparison Report',
          reportPeriod: dateFormatter.format(reportPeriod),
          companyName: username,
          font: ttf,
          boldFont: boldTtf,
        ),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          _buildComparisonSummary(
            propertiesData: sortedPropertiesData,
            properties: properties,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
          
          pw.SizedBox(height: 30),
          
          _buildComparisonTable(
            propertiesData: sortedPropertiesData,
            properties: properties,
            currencyFormat: currencyFormat,
            font: ttf,
            boldFont: boldTtf,
          ),
        ],
      ),
    );

    // Save the PDF document
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/property_comparison_${DateFormat('yyyy_MM').format(reportPeriod)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Helper widgets for PDF generation
  pw.Widget _buildHeader({
    required String reportTitle,
    required String reportPeriod,
    required String companyName,
    String? propertyName,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                  ),
                ),
                if (propertyName != null)
                  pw.Text(
                    propertyName,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                  reportPeriod,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPropertyInfoSection({
    required Property property,
    required NumberFormat currencyFormat,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Property Information',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Type:', property.propertyType, font, boldFont),
              ),
              pw.Expanded(
                child: _buildInfoRow(
                  'Purchase Price:',
                  property.purchasePrice != null
                      ? currencyFormat.format(property.purchasePrice)
                      : 'N/A',
                  font,
                  boldFont,
                ),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow(
                  'Bedrooms:',
                  property.bedrooms?.toString() ?? 'N/A',
                  font,
                  boldFont,
                ),
              ),
              pw.Expanded(
                child: _buildInfoRow(
                  'Current Value:',
                  property.currentValue != null
                      ? currencyFormat.format(property.currentValue)
                      : 'N/A',
                  font,
                  boldFont,
                ),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow(
                  'Bathrooms:',
                  property.bathrooms?.toString() ?? 'N/A',
                  font,
                  boldFont,
                ),
              ),
              pw.Expanded(
                child: _buildInfoRow(
                  'Square Feet:',
                  property.squareFeet?.toString() ?? 'N/A',
                  font,
                  boldFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection({
    required Map<String, dynamic> overallData,
    required NumberFormat currencyFormat,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    final totalIncome = overallData['totalIncome'] ?? 0.0;
    final totalExpenses = overallData['totalExpenses'] ?? 0.0;
    final netProfit = overallData['netProfit'] ?? 0.0;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
            ),
          ),
          pw.Divider(),
          _buildFinancialRow(
            'Total Income:',
            currencyFormat.format(totalIncome),
            font,
            boldFont,
            valueColor: PdfColors.green700,
          ),
          _buildFinancialRow(
            'Total Expenses:',
            currencyFormat.format(totalExpenses),
            font,
            boldFont,
            valueColor: PdfColors.red700,
          ),
          pw.Divider(thickness: 2),
          _buildFinancialRow(
            'Net Profit/Loss:',
            currencyFormat.format(netProfit),
            font,
            boldFont,
            valueColor: netProfit >= 0 ? PdfColors.green900 : PdfColors.red900,
            isBold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont, {
    PdfColor? valueColor,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isBold ? boldFont : font,
              fontSize: isBold ? 12 : 11,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: isBold ? boldFont : font,
              fontSize: isBold ? 12 : 11,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIncomeDetailsSection({
    required Map<String, dynamic> overallData,
    required NumberFormat currencyFormat,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    final rentalIncome = overallData['rentalIncome'] ?? 0.0;
    final securityDeposits = overallData['securityDeposits'] ?? 0.0;
    final otherIncome = overallData['otherIncome'] ?? 0.0;
    final totalIncome = overallData['totalIncome'] ?? 0.0;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Income Details',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
            ),
          ),
          pw.Divider(),
          _buildFinancialRow(
            'Rental Income:',
            currencyFormat.format(rentalIncome),
            font,
            boldFont,
          ),
          if (securityDeposits > 0)
            _buildFinancialRow(
              'Security Deposits:',
              currencyFormat.format(securityDeposits),
              font,
              boldFont,
            ),
          if (otherIncome > 0)
            _buildFinancialRow(
              'Other Income:',
              currencyFormat.format(otherIncome),
              font,
              boldFont,
            ),
          pw.Divider(),
          _buildFinancialRow(
            'Total Income:',
            currencyFormat.format(totalIncome),
            font,
            boldFont,
            valueColor: PdfColors.green700,
            isBold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExpenseDetailsSection({
    required Map<String, dynamic> overallData,
    required NumberFormat currencyFormat,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    final totalExpenses = overallData['totalExpenses'] ?? 0.0;
    
    // Get expense categories from AppConstants
    final expenseCategories = [
      'Maintenance',
      'Repair',
      'Utilities',
      'Property Tax',
      'Insurance',
      'Mortgage',
      'Management Fee',
      'Other',
    ];
    
    // Build expense rows
    final expenseRows = <pw.Widget>[];
    
    for (var category in expenseCategories) {
      final key = 'expenses_${category.toLowerCase().replaceAll(' ', '_')}';
      final amount = overallData[key] ?? 0.0;
      
      if (amount > 0) {
        expenseRows.add(
          _buildFinancialRow(
            '$category:',
            currencyFormat.format(amount),
            font,
            boldFont,
          ),
        );
      }
    }
    
    // Add other expenses details
    final otherExpensesDetails = overallData['otherExpensesDetails'] as List<Map<String, dynamic>>? ?? [];
    
    if (otherExpensesDetails.isNotEmpty) {
      expenseRows.add(pw.Divider());
      expenseRows.add(
        pw.Text(
          'Other Expenses Details:',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
          ),
        ),
      );
      
      for (var expense in otherExpensesDetails) {
        expenseRows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 2),
            child: _buildFinancialRow(
              expense['description'] ?? 'Unspecified:',
              currencyFormat.format(expense['amount'] ?? 0.0),
              font,
              boldFont,
            ),
          ),
        );
      }
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Expense Details',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
            ),
          ),
          pw.Divider(),
          ...expenseRows,
          pw.Divider(),
          _buildFinancialRow(
            'Total Expenses:',
            currencyFormat.format(totalExpenses),
            font,
            boldFont,
            valueColor: PdfColors.red700,
            isBold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildComparisonSummary({
    required List<MapEntry<String, Map<String, dynamic>>> propertiesData,
    required List<Property> properties,
    required NumberFormat currencyFormat,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    // Calculate totals
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    double totalProfit = 0.0;
    
    for (var entry in propertiesData) {
      totalIncome += entry.value['totalIncome'] ?? 0.0;
      totalExpenses += entry.value['totalExpenses'] ?? 0.0;
      totalProfit += entry.value['netProfit'] ?? 0.0;
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Portfolio Summary',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, // Changed from spaceAround
            children: [
              _buildSimpleSummaryBox(
                'Total Properties',
                properties.length.toString(),
                PdfColors.blue,
                font,
                boldFont,
              ),
              _buildSimpleSummaryBox(
                'Total Income',
                currencyFormat.format(totalIncome),
                PdfColors.green700,
                font,
                boldFont,
              ),
              _buildSimpleSummaryBox(
                'Total Expenses',
                currencyFormat.format(totalExpenses),
                PdfColors.red700,
                font,
                boldFont,
              ),
              _buildSimpleSummaryBox(
                'Net Profit/Loss',
                currencyFormat.format(totalProfit),
                totalProfit >= 0 ? PdfColors.green700 : PdfColors.red700,
                font,
                boldFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Updated summary box without background color and smaller width
  pw.Widget _buildSimpleSummaryBox(
    String label,
    String value,
    PdfColor color,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      width: 100, // Reduced from 120 to 100
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        // Removed background color
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: color, // Use the main color directly
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10, // Reduced from 12 to 10
              color: color, // Use the main color directly
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildComparisonTable({
    required List<MapEntry<String, Map<String, dynamic>>> propertiesData,
    required List<Property> properties,
    required NumberFormat currencyFormat,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    // Find property by ID
    Property findProperty(String id) {
      return properties.firstWhere(
        (property) => property.id == id,
        orElse: () => Property(
          id: id,
          userId: '',
          address: 'Unknown Property',
          propertyType: '',
          createdAt: DateTime.now(),
        ),
      );
    }
    
    // Table headers
    final headers = [
      'Property',
      'Type',
      'Income',
      'Expenses',
      'Profit/Loss',
      'Margin %',
    ];
    
    // Table rows
    final rows = <List<String>>[];
    
    for (var entry in propertiesData) {
      final property = findProperty(entry.key);
      final data = entry.value;
      
      final income = data['totalIncome'] ?? 0.0;
      final expenses = data['totalExpenses'] ?? 0.0;
      final profit = data['netProfit'] ?? 0.0;
      
      // Calculate profit margin
      final margin = income > 0 ? (profit / income * 100) : 0.0;
      
      rows.add([
        property.address,
        property.propertyType,
        currencyFormat.format(income),
        currencyFormat.format(expenses),
        currencyFormat.format(profit),
        '${margin.toStringAsFixed(1)}%',
      ]);
    }
    
    return pw.Table.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        font: boldFont,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
      headerAlignment: pw.Alignment.center,
      cellStyle: pw.TextStyle(
        font: font,
        fontSize: 9,
      ),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {
        0: pw.Alignment.centerLeft,  // Property name left-aligned
        1: pw.Alignment.center,      // Type centered
        2: pw.Alignment.centerRight, // Income right-aligned
        3: pw.Alignment.centerRight, // Expenses right-aligned
        4: pw.Alignment.centerRight, // Profit right-aligned
        5: pw.Alignment.center,      // Margin % centered
      },
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 0.5,
      ),
      cellHeight: 25,
    );
  }

  // Helper method to share the PDF file
  Future<void> sharePdf(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Profit & Loss Statement',
      text: 'Generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }

  // Add this method to the PdfService class in lib/services/pdf_service.dart

// Generate a payment receipt PDF
  Future<File> generatePaymentReceiptPdf({
    required Payment payment,
    required Property property,
    required Tenant tenant,
    required Lease lease,
    required String landlordName,
  }) async {
    try {
      // Load font with error handling
      late pw.Font ttf;
      late pw.Font boldTtf;
      
      try {
        final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
        ttf = pw.Font.ttf(fontData);
        final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
        boldTtf = pw.Font.ttf(boldFontData);
      } catch (e) {
        print('Font loading error: $e - Using default font');
        ttf = pw.Font.helvetica();
        boldTtf = pw.Font.helveticaBold();
      }

      // Create PDF document
      final pdf = pw.Document();

      // Format currency values and dates
      final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
      final dateFormatter = DateFormat('MMMM dd, yyyy');
      
      // Format receipt number based on payment ID
      final receiptNumber = 'RCP-${payment.id.substring(0, 8).toUpperCase()}';
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Receipt Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PAYMENT RECEIPT',
                            style: pw.TextStyle(
                              font: boldTtf,
                              fontSize: 24,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Receipt #: $receiptNumber',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'Date: ${dateFormatter.format(DateTime.now())}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        width: 100,
                        height: 100,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              font: boldTtf,
                              fontSize: 32,
                              color: PdfColors.green700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 40),
                  
                  // Landlord and Tenant Info
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Landlord info
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'LANDLORD:',
                              style: pw.TextStyle(
                                font: boldTtf,
                                fontSize: 14,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              landlordName,
                              style: pw.TextStyle(
                                font: boldTtf,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tenant info
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TENANT:',
                              style: pw.TextStyle(
                                font: boldTtf,
                                fontSize: 14,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              '${tenant.firstName} ${tenant.lastName}',
                              style: pw.TextStyle(
                                font: boldTtf,
                                fontSize: 12,
                              ),
                            ),
                            if (tenant.email != null)
                              pw.Text(
                                tenant.email!,
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                ),
                              ),
                            if (tenant.phone != null)
                              pw.Text(
                                tenant.phone!,
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  // Property Information
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROPERTY:',
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        property.address,
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        property.propertyType,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  // Payment Information
                  pw.Text(
                    'PAYMENT DETAILS',
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  
                  // Payment table
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Table(
                      border: pw.TableBorder.symmetric(
                        inside: pw.BorderSide(color: PdfColors.grey300),
                      ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.5), // Increased width for description
                        1: const pw.FlexColumnWidth(1.5), // Increased width for date
                        2: const pw.FlexColumnWidth(1.5), // Increased width for method
                        3: const pw.FlexColumnWidth(1.2), // Increased width for amount
                      },
                      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        // Header row
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Description',
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Payment Date',
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Payment Method',
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Amount',
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        // Payment data row
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Rent Payment for ${dateFormatter.format(payment.paymentDate).split(' ')[0]}',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                dateFormatter.format(payment.paymentDate),
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                payment.paymentMethod ?? 'Not specified',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                currencyFormat.format(payment.amount),
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        // Optional notes row if notes exist
                        if (payment.notes != null && payment.notes!.isNotEmpty)
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  'Notes:',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  payment.notes!,
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                              pw.Container(), // Empty cell for alignment
                              pw.Container(), // Empty cell for alignment
                            ],
                          ),
                        // Total row
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                          ),
                          children: [
                            pw.Container(), // Empty cell for alignment
                            pw.Container(), // Empty cell for alignment
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'TOTAL PAID:',
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                currencyFormat.format(payment.amount),
                                style: pw.TextStyle(
                                  font: boldTtf,
                                  fontSize: 12,
                                  color: PdfColors.green800,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 40),
                  
                  // Signature line
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 200,
                              child: pw.Divider(thickness: 1),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Landlord Signature',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  pw.Spacer(),
                  
                  // Footer
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                    ),
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'This is an electronically generated receipt.',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          'Generated on: ${dateFormatter.format(DateTime.now())}',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save the PDF document
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/payment_receipt_${payment.id.substring(0, 8)}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      print('Error generating payment receipt PDF: $e');
      // Return a basic PDF with error message
      return _generateBasicErrorPdf(
        'Payment Receipt', 
        DateTime.now(),
        'Error generating receipt'
      );
    }
  }

  // Add this method to the PdfService class

  // Method to generate a basic fallback PDF in case of errors
  Future<File> _generateBasicErrorPdf(
    String reportTitle,
    DateTime reportPeriod,
    String username,
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                reportTitle,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Report Period: ${DateFormat('MMMM yyyy').format(reportPeriod)}'),
              pw.Text('User: $username'),
              pw.SizedBox(height: 20),
              pw.Text('Error occurred during PDF generation with formatting.'),
              pw.Text('Basic report has been generated instead.'),
              pw.Text('Please check the app logs for more information.'),
            ],
          );
        },
      ),
    );
    
    // Save the basic PDF document
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/basic_report_${DateFormat('yyyy_MM').format(reportPeriod)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}