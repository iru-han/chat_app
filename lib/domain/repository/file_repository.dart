import 'dart:typed_data';

abstract interface class FileRepository {
  Future<String> uploadChatFile(String roomId, String userId, String filePath, Uint8List fileBytes, String fileType);

    Future<String?> uploadShareFile(String bucketName, String filePath, Uint8List fileBytes, String contentType);
}