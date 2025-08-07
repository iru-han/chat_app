import 'dart:typed_data';
import 'package:oboa_chat_app/data/data_source/file_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFileDataSourceImpl implements FileDataSource {
  final SupabaseClient _supabase;

  SupabaseFileDataSourceImpl(this._supabase);

  @override
  Future<String> uploadFile(String bucketName, String path, Uint8List fileBytes, {String? contentType, bool? upsert}) async {
    try {
      // Supabase Storage 업로드 (uploadData는 Uint8List를 받음)
      // flutter_supabase 2.x 버전에서는 uploadData 메서드가 더 명확합니다.
      print("uploadFile bucketName : ${bucketName}");
      print("uploadFile path : ${path}");
      final String uploadedPath = await _supabase.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: upsert ?? true,
        ),
      );
      print("SupabaseFileDataSourceImpl uploadedPath : ${uploadedPath}");
      return uploadedPath; // 업로드된 파일의 경로 반환
    } catch (e) {
      print('SupabaseFileDataSourceImpl: Error uploading file: $e');
      rethrow;
    }
  }

  @override
  Future<String> getPublicUrl(String bucketName, String path) async {
    try {
      print("path :: ${path}");
      final String correctedPath = path.startsWith('$bucketName/')
          ? path.substring(bucketName.length + 1)
          : path;

      final String publicUrl = _supabase.storage.from(bucketName).getPublicUrl(correctedPath);
      print("SupabaseFileDataSourceImpl bucketName : ${bucketName}");
      print("SupabaseFileDataSourceImpl publicUrl : ${publicUrl}");
      return publicUrl;
    } catch (e) {
      print('SupabaseFileDataSourceImpl: Error getting public URL: $e');
      rethrow;
    }
  }
}