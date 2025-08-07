// lib/domain/use_case/upload_file_use_case.dart

import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:oboa_chat_app/domain/service/ai_service.dart';
import 'package:path/path.dart' as p;
import '../model/chat_message.dart'; // ChatMessage 모델 import
import '../repository/file_repository.dart';
import '../repository/chat_repository.dart'; // ChatRepository import (메시지 전송 위해)

class UploadFileUseCase {
  final FileRepository _fileRepository;
  final ChatRepository _chatRepository; // ChatRepository 추가
  final AIChatService _aiChatService; // 필드 추가

  UploadFileUseCase({
    required FileRepository fileRepository,
    required ChatRepository chatRepository,
    required AIChatService aiChatService, // 생성자 매개변수 추가
  })  : _fileRepository = fileRepository,
        _chatRepository = chatRepository,
        _aiChatService = aiChatService;

  // 업로드된 파일 메시지 객체를 반환하도록 execute 메서드 시그니처 변경
  Future<ChatMessage> execute(String roomId, String userId, String filePath, Uint8List fileBytes, String fileType, {String? fileName}) async {
    try {
      // 1. 파일 Storage 업로드
      final publicUrl = await _fileRepository.uploadChatFile(
          roomId, userId, filePath, fileBytes, fileType);
      print("publicUrl : ${publicUrl}");

      // 2. Claude Files API에 파일 업로드 (document 또는 pdf일 경우)
      String? claudeFileId;
      print("fileType : ${fileType}");
      if (fileType == 'document' || fileType == 'pdf' || fileType == 'file') {
        try {
          final mimeType = lookupMimeType(filePath) ??
              'application/octet-stream';
          claudeFileId = await _aiChatService.uploadFileToClaude(
              fileBytes, mimeType, fileName ?? p.basename(filePath));
          print('File uploaded to Claude: $claudeFileId');
        } catch (e) {
          print('Error uploading file to Claude: $e');
          // 오류가 발생해도 진행
        }
      }

      // 2. 파일 메시지 생성
      final fileMessage = ChatMessage(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        roomId: roomId,
        senderId: userId,
        // 파일 메시지의 발신자는 현재 사용자
        text: fileType == 'image' ? '이미지 전송' : '파일 전송: ${fileName ??
            p.basename(filePath)}',
        createdAt: DateTime.now(),
        type: fileType,
        imageUrl: fileType == 'image' ? publicUrl : null,
        fileUrl: fileType != 'image' ? publicUrl : null,
        fileName: fileName ?? p.basename(filePath),
        claudeFileId: claudeFileId, // Claude File ID 저장
      );

      // 3. 파일 메시지를 DB에 저장
      await _chatRepository.sendMessage(fileMessage); // <- 파일 메시지 DB 저장
      await _chatRepository.updateLastMessage(
          roomId, fileMessage.text, fileMessage.createdAt);
      print("fileMessage : $fileMessage");

      return fileMessage; // <- 파일 메시지 객체를 반환
    } catch (e) {
      print('Error in UploadFileUseCase: $e');
      rethrow; // 오류를 다시 던져서 상위에서 처리하도록 함
    }
  }
}