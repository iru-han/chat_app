import 'dart:typed_data';

abstract interface class FileDataSource {
  Future<String> uploadFile(String bucketName, String path, Uint8List fileBytes, {String? contentType, bool? upsert});
  Future<String> getPublicUrl(String bucketName, String path);
}