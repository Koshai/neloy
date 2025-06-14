import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'secure_file_service.dart';
// Create alias to avoid naming conflicts
import 'package:path/path.dart' as path_helper;

class LocalFileStorageService {
  // Get the app's documents directory for storing files
  Future<Directory> _getAppDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  // Create folder structure for organizing files
  Future<Directory> _createFolderIfNotExists(String folderPath) async {
    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // Upload (save) an encrypted file to local storage
  Future<String> uploadFile({
    required File file,
    required String bucket, // Used as folder name for organization
    required String folder, // Sub-folder (like property/tenant ID)
  }) async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final bucketDir = await _createFolderIfNotExists(path.join(appDir.path, bucket));
      final folderDir = await _createFolderIfNotExists(path.join(bucketDir.path, folder));
      
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final encryptedFileName = '${timestamp}_${fileName}.enc';
      final localFilePath = path.join(folderDir.path, encryptedFileName);
      
      // Encrypt the file before saving locally
      final encryptedBytes = await SecureFileService.encryptFile(file);
      
      // Save encrypted file to local storage
      final localFile = File(localFilePath);
      await localFile.writeAsBytes(encryptedBytes);
      
      // Return relative path for database storage
      final relativePath = path.join(bucket, folder, encryptedFileName);
      
      print('LOCAL_STORAGE: File saved locally at: $localFilePath');
      print('LOCAL_STORAGE: Relative path: $relativePath');
      
      return relativePath;
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to save file locally: $e');
      throw 'Failed to save file locally: $e';
    }
  }

  // Download (read) and decrypt a file from local storage
  Future<File?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final localFilePath = path_helper.join(appDir.path, path);
      final localFile = File(localFilePath);
      
      if (!await localFile.exists()) {
        print('LOCAL_STORAGE ERROR: File not found at: $localFilePath');
        return null;
      }
      
      // Read encrypted bytes from local file
      final encryptedBytes = await localFile.readAsBytes();
      
      // Get original filename without the .enc extension and timestamp
      final fileName = path_helper.basename(path)
          .replaceAll('.enc', '')
          .replaceAll(RegExp(r'^\d+_'), ''); // Remove timestamp prefix
      
      // Generate a temporary path for the decrypted file
      final outputPath = await SecureFileService.generateTempFilePath(fileName);
      
      // Decrypt the file
      final decryptedFile = await SecureFileService.decryptFile(
        encryptedBytes,
        outputPath,
      );
      
      print('LOCAL_STORAGE: File decrypted and available at: ${decryptedFile.path}');
      return decryptedFile;
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to read file locally: $e');
      return null;
    }
  }

  // Delete a file from local storage
  Future<bool> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final localFilePath = path_helper.join(appDir.path, filePath);
      final localFile = File(localFilePath);
      
      if (await localFile.exists()) {
        await localFile.delete();
        print('LOCAL_STORAGE: File deleted from: $localFilePath');
        return true;
      } else {
        print('LOCAL_STORAGE: File not found for deletion: $localFilePath');
        return false;
      }
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to delete file: $e');
      return false;
    }
  }

  // Get file size
  Future<int> getFileSize({
    required String bucket,
    required String filePath,
  }) async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final localFilePath = path_helper.join(appDir.path, filePath);
      final localFile = File(localFilePath);
      
      if (await localFile.exists()) {
        return await localFile.length();
      }
      return 0;
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to get file size: $e');
      return 0;
    }
  }

  // List all files in a specific folder
  Future<List<String>> listFiles({
    required String bucket,
    required String folder,
  }) async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final folderPath = path_helper.join(appDir.path, bucket, folder);
      final directory = Directory(folderPath);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory.list().toList();
      return files
          .where((entity) => entity is File && entity.path.endsWith('.enc'))
          .map((file) => path_helper.relative(file.path, from: appDir.path))
          .toList();
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to list files: $e');
      return [];
    }
  }

  // Get total storage used by the app
  Future<int> getTotalStorageUsed() async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      return await _getDirectorySize(appDir);
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to calculate storage usage: $e');
      return 0;
    }
  }

  // Helper method to calculate directory size recursively
  Future<int> _getDirectorySize(Directory directory) async {
    int totalSize = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to calculate directory size: $e');
    }
    return totalSize;
  }

  // Clean up temporary files (call this periodically)
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = await tempDir.list().toList();
      
      for (final entity in tempFiles) {
        if (entity is File) {
          // Delete temp files older than 1 hour
          final stats = await entity.stat();
          final ageInHours = DateTime.now().difference(stats.modified).inHours;
          
          if (ageInHours > 1) {
            await entity.delete();
            print('LOCAL_STORAGE: Cleaned up temp file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('LOCAL_STORAGE ERROR: Failed to clean up temp files: $e');
    }
  }
}

