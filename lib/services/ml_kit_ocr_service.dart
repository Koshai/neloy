// lib/services/ml_kit_ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ReceiptData {
  final double? amount;
  final DateTime? date;
  final String? description;
  final String? expenseType;
  final String rawText;

  ReceiptData({
    this.amount,
    this.date,
    this.description,
    this.expenseType,
    required this.rawText,
  });
}

class MlKitOcrService {
  final _textRecognizer = TextRecognizer();

  // Capture image using camera or gallery
  Future<File?> captureImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo != null) {
      return File(photo.path);
    }
    return null;
  }

  // Process image and extract text
  Future<ReceiptData?> processReceiptImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return null;
      }
      
      // Parse the recognized text
      return _parseReceiptText(recognizedText.text);
    } catch (e) {
      print('Error processing receipt: $e');
      return null;
    }
  }

  // Close resources
  void dispose() {
    _textRecognizer.close();
  }

  // Parse receipt text to extract relevant information
  ReceiptData _parseReceiptText(String text) {
    // Normalized text (lowercase for easier matching)
    final normalizedText = text.toLowerCase();
    
    // Extract amount (look for patterns like $ or total)
    double? amount = _extractAmount(normalizedText);
    
    // Extract date
    DateTime? date = _extractDate(normalizedText);
    
    // Extract description 
    String? description = _extractDescription(normalizedText);
    
    // Try to detect expense type
    String? expenseType = _detectExpenseType(normalizedText);

    return ReceiptData(
      amount: amount,
      date: date,
      description: description,
      expenseType: expenseType,
      rawText: text,
    );
  }

  double? _extractAmount(String text) {
    // Look for total amount patterns
    final patterns = [
      RegExp(r'total:?\s*\$?\s*(\d+[.,]\d{2})'),
      RegExp(r'amount:?\s*\$?\s*(\d+[.,]\d{2})'),
      RegExp(r'sum:?\s*\$?\s*(\d+[.,]\d{2})'),
      RegExp(r'(\$\s*\d+[.,]\d{2})'),
      RegExp(r'(\d+[.,]\d{2}\s*\$)'),
      // Money values with $ sign and without
      RegExp(r'(\d+\.\d{2})'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        // Get the last match (usually the total at the bottom)
        final match = matches.last;
        final amountStr = match.group(1)?.replaceAll(RegExp(r'[^\d.]'), '') ?? '';
        
        try {
          return double.parse(amountStr);
        } catch (e) {
          // Continue trying other patterns if parsing fails
          continue;
        }
      }
    }
    
    return null;
  }

  DateTime? _extractDate(String text) {
    // Look for date patterns (MM/DD/YYYY, MM-DD-YYYY, etc.)
    final patterns = [
      // MM/DD/YYYY
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})'),
      // YYYY/MM/DD
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
      // Month name formats
      RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})[\s,]+(\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        try {
          final match = matches.first;
          
          // Determine which format we matched
          if (pattern.pattern.startsWith(r'(\d{1,2})[/\-]')) {
            // MM/DD/YYYY format
            int month = int.parse(match.group(1)!);
            int day = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);
            
            // Handle 2-digit year
            if (year < 100) {
              year += 2000;
            }
            
            return DateTime(year, month, day);
          } else if (pattern.pattern.startsWith(r'(\d{4})[/\-]')) {
            // YYYY/MM/DD format
            int year = int.parse(match.group(1)!);
            int month = int.parse(match.group(2)!);
            int day = int.parse(match.group(3)!);
            
            return DateTime(year, month, day);
          } else {
            // Month name format
            final monthName = match.group(1)!.toLowerCase();
            int month = _getMonthNumber(monthName);
            int day = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);
            
            // Handle 2-digit year
            if (year < 100) {
              year += 2000;
            }
            
            return DateTime(year, month, day);
          }
        } catch (e) {
          // Continue trying other patterns if parsing fails
          continue;
        }
      }
    }
    
    // If no date found, use today's date
    return DateTime.now();
  }

  int _getMonthNumber(String monthName) {
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    
    for (final entry in months.entries) {
      if (monthName.startsWith(entry.key)) {
        return entry.value;
      }
    }
    
    return 1; // Default to January if no match
  }

  String? _extractDescription(String text) {
    // Try to find a description by looking for common keywords
    final descriptionPatterns = [
      RegExp(r'item[s]?:?\s*(.+)', caseSensitive: false),
      RegExp(r'description:?\s*(.+)', caseSensitive: false),
      RegExp(r'product:?\s*(.+)', caseSensitive: false),
    ];

    for (final pattern in descriptionPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final desc = match.group(1)?.trim();
        if (desc != null && desc.isNotEmpty) {
          // Limit description to first 5 words
          final words = desc.split(' ');
          return words.take(5).join(' ');
        }
      }
    }

    // If no description was found with patterns, use the first line
    // that doesn't look like a date, amount, or expense type
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.length > 3 && 
          line.length < 50 &&
          !line.contains(RegExp(r'^\d+[.,]\d{2}$')) &&
          !line.contains(RegExp(r'^\$\d+[.,]\d{2}$')) &&
          !line.contains(RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}'))) {
        return line.trim();
      }
    }
    
    return null;
  }

  String? _detectExpenseType(String text) {
    // Common expense keywords to detect type
    final typeMatchers = {
      'Maintenance': ['maintenance', 'repair', 'fix', 'service', 'plumb', 'electric'],
      'Repair': ['repair', 'fix', 'broken', 'replacement'],
      'Utilities': ['utility', 'utilities', 'water', 'electricity', 'gas', 'power', 'bill'],
      'Property Tax': ['tax', 'property tax'],
      'Insurance': ['insurance', 'policy', 'coverage'],
      'Mortgage': ['mortgage', 'loan', 'payment', 'interest'],
      'Management Fee': ['management', 'fee', 'commission', 'service charge'],
    };

    for (final type in typeMatchers.entries) {
      for (final keyword in type.value) {
        if (text.contains(keyword)) {
          return type.key;
        }
      }
    }
    
    return 'Other';
  }
}