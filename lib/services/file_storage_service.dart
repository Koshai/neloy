import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'secure_file_service.dart';
import 'local_file_storage_service.dart';

class FileStorageService {
  final _supabase = Supabase.instance.client;
  final _localStorage = LocalFileStorageService();

  // Flag to determine storage method (set to false for local storage)
  static const bool USE_CLOUD_STORAGE = false;

  // Main upload method - routes to local or cloud storage
  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String folder,
  }) async {
    if (USE_CLOUD_STORAGE) {
      return await _uploadToCloud(
        file: file,
        bucket: bucket,
        folder: folder,
      );
    } else {
      return await _localStorage.uploadFile(
        file: file,
        bucket: bucket,
        folder: folder,
      );
    }
  }

  // Main download method - routes to local or cloud storage
  Future<File?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    if (USE_CLOUD_STORAGE) {
      return await _downloadFromCloud(
        bucket: bucket,
        path: path,
      );
    } else {
      return await _localStorage.downloadFile(
        bucket: bucket,
        path: path,
      );
    }
  }

  // Delete file - routes to local or cloud storage
  Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    if (USE_CLOUD_STORAGE) {
      return await _deleteFromCloud(
        bucket: bucket,
        path: path,
      );
    } else {
      return await _localStorage.deleteFile(
        bucket: bucket,
        filePath: path,
      );
    }
  }

  // COMMENTED OUT - CLOUD STORAGE METHODS (FOR FUTURE USE)
  
  // Upload an encrypted file to cloud storage
  Future<String> _uploadToCloud({
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
      print('Error uploading encrypted file to cloud: $e');
      throw e;
    }
  }

  // Download and decrypt a file from cloud storage
  Future<File?> _downloadFromCloud({
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
      print('Error downloading encrypted file from cloud: $e');
      return null;
    }
  }

  // Delete file from cloud storage
  Future<bool> _deleteFromCloud({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage
          .from(bucket)
          .remove([path]);
      return true;
    } catch (e) {
      print('Error deleting file from cloud: $e');
      return false;
    }
  }
  

  // LOCAL STORAGE METHODS (CURRENTLY ACTIVE)

  // Get file size from local storage
  Future<int> getFileSize({
    required String bucket,
    required String path,
  }) async {
    return await _localStorage.getFileSize(
      bucket: bucket,
      filePath: path,
    );
  }

  // List files in local storage
  Future<List<String>> listFiles({
    required String bucket,
    required String folder,
  }) async {
    return await _localStorage.listFiles(
      bucket: bucket,
      folder: folder,
    );
  }

  // Get total storage used
  Future<int> getTotalStorageUsed() async {
    return await _localStorage.getTotalStorageUsed();
  }

  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    await _localStorage.cleanupTempFiles();
  }

  // Helper method to get content type (kept for compatibility)
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

  // Method to check available storage space
  Future<int> getAvailableStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stats = await directory.stat();
      // This is a rough estimate - actual implementation may vary by platform
      return 1024 * 1024 * 1024; // Return 1GB as default available space
    } catch (e) {
      print('Error getting available storage: $e');
      return 0;
    }
  }

  // Method to migrate from cloud to local (for future use)
  /*
  Future<void> migrateFromCloudToLocal() async {
    // Implementation for migrating existing cloud files to local storage
    // This would be used if you decide to switch from cloud to local later
  }
  */

  // Method to migrate from local to cloud (for future use)
  /*
  Future<void> migrateFromLocalToCloud() async {
    // Implementation for migrating existing local files to cloud storage
    // This would be used if you decide to switch from local to cloud later
  }
  */
}