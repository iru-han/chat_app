import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:oboa_chat_app/domain/repository/file_repository.dart'; // FileRepository를 사용하려면 import

class UploadCapturedImageUseCase {
  final FileRepository? _fileRepository; // 필요 시 사용

  UploadCapturedImageUseCase({required FileRepository? fileRepository})
      : _fileRepository = fileRepository;

  Future<String?> execute(Uint8List pngBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final String tempFileName = "share_capture_${DateTime.now().millisecondsSinceEpoch}.png";
      final File tempFile = File('${directory.path}/$tempFileName');
      await tempFile.writeAsBytes(pngBytes);
      print('Captured image saved to temporary file: ${tempFile.path}');

      final publicUrl = await _fileRepository?.uploadShareFile(
        'capture-images', // 적절한 버킷 이름 설정
        tempFileName, // 저장 경로 설정
        pngBytes,
        'image/png',
      );

      print('Captured image uploaded to Supabase: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error during capture and upload: $e');
      return null;
    }
  }
}