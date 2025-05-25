import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class SecureFileService {
  static const _secureStorageKey = 'user_encryption_key';
  static final _secureStorage = FlutterSecureStorage();
  
  // Generate a random encryption key
  static String _generateEncryptionKey() {
    final key = encrypt.Key.fromSecureRandom(32); // 256-bit key
    return key.base64;
  }
  
  // Store the encryption key securely
  static Future<void> _storeEncryptionKey(String encryptionKey) async {
    await _secureStorage.write(
      key: _secureStorageKey,
      value: encryptionKey,
    );
  }
  
  // Retrieve the encryption key
  static Future<String?> _getEncryptionKey() async {
    return await _secureStorage.read(key: _secureStorageKey);
  }
  
  // Ensure an encryption key exists and return it
  static Future<String> ensureEncryptionKey() async {
    String? key = await _getEncryptionKey();
    if (key == null) {
      key = _generateEncryptionKey();
      await _storeEncryptionKey(key);
    }
    return key;
  }
  
  // Encrypt a file before uploading
  static Future<Uint8List> encryptFile(File file) async {
    final encryptionKey = await ensureEncryptionKey();
    final bytes = await file.readAsBytes();
    
    final key = encrypt.Key.fromBase64(encryptionKey);
    final iv = encrypt.IV.fromSecureRandom(16);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    
    // Prepend IV to encrypted data for decryption later
    final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
    result.setRange(0, iv.bytes.length, iv.bytes);
    result.setRange(iv.bytes.length, result.length, encrypted.bytes);
    
    return result;
  }
  
  // Decrypt a file after downloading
  static Future<File> decryptFile(
    Uint8List encryptedBytes,
    String outputPath,
  ) async {
    final encryptionKey = await _getEncryptionKey();
    if (encryptionKey == null) {
      throw 'Encryption key not found. Cannot decrypt file.';
    }
    
    final key = encrypt.Key.fromBase64(encryptionKey);
    
    // Extract IV from the beginning of the data
    final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
    final encryptedData = encrypt.Encrypted(encryptedBytes.sublist(16));
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decryptBytes(encryptedData, iv: iv);
    
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(decrypted);
    return outputFile;
  }
  
  // Generate a temporary file path for decrypted files
  static Future<String> generateTempFilePath(String originalFileName) async {
    final tempDir = await getTemporaryDirectory();
    final random = Random().nextInt(10000);
    return '${tempDir.path}/${random}_${originalFileName}';
  }
}