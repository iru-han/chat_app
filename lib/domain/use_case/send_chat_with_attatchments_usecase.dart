// lib/domain/use_case/send_chat_with_attachments_use_case.dart

import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/domain/model/selected_attachment.dart';
import 'package:oboa_chat_app/domain/use_case/send_chat_message_use_case.dart';
import 'package:oboa_chat_app/domain/use_case/upload_file_use_case.dart';
import 'package:uuid/uuid.dart';

class SendChatWithAttachmentsUseCase {
  final UploadFileUseCase _uploadFileUseCase;
  final SendChatMessageUseCase _sendChatMessageUseCase;

  SendChatWithAttachmentsUseCase({
    required UploadFileUseCase uploadFileUseCase,
    required SendChatMessageUseCase sendChatMessageUseCase,
  })  : _uploadFileUseCase = uploadFileUseCase,
        _sendChatMessageUseCase = sendChatMessageUseCase;

  Stream<ChatMessage> execute({
    required String roomId,
    required String userId,
    required String text,
    required List<SelectedAttachment> attachments,
    required List<ChatMessage> currentMessages,
  }) async* {
    final List<ChatMessage> messagesForClaude = [];

    for (int i = 0; i < currentMessages.length; i++) {
      final message = currentMessages[i];
      print("message : ${message}");

      // 1. 빈 텍스트 메시지, AI 실패 응답은 무조건 건너뛰기
      if (message.text.trim().isEmpty ||
          (message.senderId == AppConstants.aiSenderId && message.text.contains('AI 응답을 가져오는 데 실패했습니다.') ||
          message.type == 'pdf') // pdf 파일은 지원하지 않음
      ) {
        continue;
      }

      // 2. 사용자가 보낸 메시지인 경우
      if (message.senderId == userId) {
        // 다음 메시지가 AI 응답인지 확인 (완전한 대화 턴)
        if (i + 1 < currentMessages.length && currentMessages[i + 1].senderId == AppConstants.aiSenderId) {
          messagesForClaude.add(message);
          messagesForClaude.add(currentMessages[i + 1]);
          i++; // AI 메시지를 추가했으므로 다음 루프에서 건너뛰기
        } else {
          // 마지막 메시지가 사용자 메시지인 경우 (응답 대기 중)
          messagesForClaude.add(message);
        }
      }
      // 3. AI가 보낸 메시지인 경우, 바로 컨텍스트에 추가
      else if (message.senderId == AppConstants.aiSenderId) {
        messagesForClaude.add(message);
      }
    }

    // 4. 마지막 메시지가 사용자 메시지라면(응답 대기 중) 컨텍스트에 추가
    if (currentMessages.isNotEmpty && currentMessages.last.senderId == userId) {
      messagesForClaude.add(currentMessages.last);
    }

    // 4. 마지막 메시지가 사용자 메시지라면(응답 대기 중) 컨텍스트에 추가
    if (currentMessages.isNotEmpty && currentMessages.last.senderId == userId) {
      messagesForClaude.add(currentMessages.last);
    }

    final List<Map<String, dynamic>> imageAttachmentsForClaude = []; // 이미지 파일
    final List<Map<String, String>> claudeFileReferences = []; // 클로드 파일

    print("roomId : $roomId");
    print("userId : $userId");
    print("text : $text");
    print("attachments : $attachments");

    print("currentMessages : $currentMessages");
    print("messagesForClaude : $messagesForClaude");
    print("imageAttachmentsForClaude : $imageAttachmentsForClaude");
    print("claudeFileReferences : $claudeFileReferences");

    // 첨부 파일 업로드 및 메시지 전송
    for (final attachment in attachments) {
      try {
        final fileMessage = await _uploadFileUseCase.execute(
          roomId,
          userId,
          attachment.path,
          attachment.bytes!,
          attachment.type,
          fileName: attachment.name,
        );
        yield fileMessage; // 업로드된 파일 메시지를 스트림으로 반환

        print("fileMessage : ${fileMessage}");
        print("attachment.type : ${attachment.type}");

        // Claude에 보낼 첨부 파일 데이터 준비
        if (attachment.type == 'image') { // 이미지일 경우 base64
          imageAttachmentsForClaude.add({
            'bytes': attachment.bytes,
            'mime_type': attachment.mimeType,
          });
        } else if (attachment.type == 'document' || attachment.type == 'pdf') {
          claudeFileReferences.add({
            'file_id': fileMessage.claudeFileId!,
            'type': attachment.type,
          });
        }
      } catch (e) {
        print('Error processing attachment: ${attachment.name}, Error: $e');
      }
    }

    // 2. 사용자 텍스트 메시지 반환
    if (text.trim().isNotEmpty) {
      final userTextMessage = ChatMessage(
        id: const Uuid().v4(),
        roomId: roomId,
        senderId: userId,
        text: text,
        createdAt: DateTime.now(),
        type: 'text',
      );
      messagesForClaude.add(userTextMessage);
      yield userTextMessage; // 스트림으로 텍스트 메시지 반환
    }

    // 텍스트 메시지 전송 및 AI 응답 받기
    if (text.isNotEmpty || attachments.isNotEmpty) {
      final aiMessage = await _sendChatMessageUseCase.execute(
        roomId,
        userId,
        text,
        messagesForClaude,
        imageAttachmentsForClaude: imageAttachmentsForClaude,
        claudeFileReferences: claudeFileReferences,
      );
      yield aiMessage; // AI 응답 메시지를 스트림으로 반환
    }
  }
}