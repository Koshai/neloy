import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'secure_file_service.dart';

class FileStorageService {
  final _supabase = Supabase.instance.client;

  // Upload an encrypted file
  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String folder,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final filePath = '${folder}/${DateTime.now().millisecondsSinceEpoch}_${fileName}.enc';
      
      // Encrypt the file before uploading
      final encryptedBytes = await SecureFileService.encryptFile(file);
      
      // Upload the encrypted file
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            encryptedBytes,
            fileOptions: FileOptions(
              contentType: 'application/octet-stream', // Generic binary type for encrypted files
            ),
          );

      return filePath;
    } catch (e) {
      print('Error uploading encrypted file: $e');
      throw e;
    }
  }

  // Download and decrypt a file
  Future<File?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      // Get original filename without the .enc extension
      final fileName = path.split('/').last.replaceAll('.enc', '');
      
      // Download encrypted bytes
      final encryptedBytes = await _supabase.storage
          .from(bucket)
          .download(path);
      
      // Generate a temporary path for the decrypted file
      final outputPath = await SecureFileService.generateTempFilePath(fileName);
      
      // Decrypt the file
      return await SecureFileService.decryptFile(
        encryptedBytes,
        outputPath,
      );
    } catch (e) {
      print('Error downloading encrypted file: $e');
      return null;
    }
  }

  // Keep your existing _getContentType method
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}