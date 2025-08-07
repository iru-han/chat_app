import 'dart:typed_data';
import 'package:oboa_chat_app/data/data_source/file_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repository/file_repository.dart';

class FileRepositoryImpl implements FileRepository {
  final FileDataSource _fileDataSource;
  static const String _chatFilesBucket = 'chat-files'; // Supabase Storage 버킷 이름

  FileRepositoryImpl({required FileDataSource fileDataSource}) : _fileDataSource = fileDataSource;

  @override
  Future<String> uploadChatFile(String roomId, String userId, String filePath, Uint8List fileBytes, String fileType) async {
    final String fileExtension = p.extension(filePath);
    // Supabase Storage 경로: chats/{room_id}/{user_id}/{timestamp}{.ext}
    final String storagePath = 'chats/$roomId/$userId/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    print("uploadChatFile storagePath :${storagePath}");

    String contentType = 'application/octet-stream';
    if (fileType == 'image') {
      contentType = 'image/${fileExtension.substring(1)}'; // .png -> image/png
    } else if (fileType == 'video') {
      contentType = 'video/${fileExtension.substring(1)}';
    }
    print("contentType :${contentType}");

    final uploadedPath = await _fileDataSource.uploadFile(_chatFilesBucket, storagePath, fileBytes, contentType: contentType);
    final publicUrl = await _fileDataSource.getPublicUrl(_chatFilesBucket, uploadedPath);
    return publicUrl;
  }

  @override
  Future<String?> uploadShareFile(String bucketName, String filePath, Uint8List fileBytes, String contentType) async {
    try {
      final uploadedPath = await _fileDataSource.uploadFile(bucketName, filePath, fileBytes, contentType: contentType);
      final publicUrl = await _fileDataSource.getPublicUrl(bucketName, uploadedPath);
      return publicUrl;
    } catch (e) {
      print('Error uploading to Supabase: $e');
      return null;
    }
  }
}