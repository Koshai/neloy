import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorageService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String folder,
  }) async {
    final fileName = file.path.split('/').last;
    final filePath = '${folder}/${DateTime.now().millisecondsSinceEpoch}_${fileName}';
    
    final bytes = await file.readAsBytes();
    final fileExt = fileName.split('.').last;
    
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _getContentType(fileExt),
          ),
        );

    return filePath;
  }

  Future<File?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final bytes = await _supabase.storage
          .from(bucket)
          .download(path);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${path.split('/').last}');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

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