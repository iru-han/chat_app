import 'dart:convert';

import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/domain/service/ai_service.dart';
import 'package:uuid/uuid.dart';

import '../model/chat_message.dart';
import '../repository/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository _chatRepository;
  final AIChatService _aiChatService;

  SendChatMessageUseCase({
    required ChatRepository chatRepository,
    required AIChatService aiChatService,
  })  : _chatRepository = chatRepository,
        _aiChatService = aiChatService;

  Future<ChatMessage>
  execute(
      String roomId,
      String senderId,
      String userMessageText,
      List<ChatMessage> currentMessagesForClaudeContext,
      {
        List<Map<String, dynamic>>? imageAttachmentsForClaude,
        List<Map<String, String>>? claudeFileReferences
      } // <- claudeFileId와 type (image/document) 리스트
      ) async {
    // 1. 과거 대화 기록을 Claude Messages API 형식에 맞춰 변환하여 messagesForClaude에 추가
    // 이거.. send Chat 이랑 클로드채팅오는거랑 구분해야할듯. 파일 채팅은 따로있어서
    final List<Map<String, dynamic>> messagesForClaude = [];

    for (final msg in currentMessagesForClaudeContext) {
      if (msg.senderId == AppConstants.aiSenderId && msg.text.contains('AI 응답을 가져오는 데 실패했습니다.')) {
        continue;
      }

      final List<Map<String, dynamic>> contentBlocks = [];
      contentBlocks.add({'type': 'text', 'text': msg.text});
      if (msg.claudeFileId != null) {
        // 이미지같은 경우엔 base64로 보내고 있음
        // if (msg.type == 'image') {
        //   contentBlocks.add({
        //     'type': 'image',
        //     'source': {
        //       'type': 'file',
        //       'file_id': msg.claudeFileId!,
        //     },
        //   });
        // } else
        if (msg.type == 'document' || msg.type == 'pdf') {
          contentBlocks.add({
            'type': 'document',
            'source': {
              'type': 'file',
              'file_id': msg.claudeFileId!,
            },
          });
        }
      }

      // 이름이 OBOA 라면 assistant
      messagesForClaude.add({
        'role': msg.senderId == AppConstants.aiSenderId ? 'assistant' : 'user',
        'content': contentBlocks,
      });
    }

    // 2. 현재 사용자 메시지 (텍스트 및 첨부 파일)를 content 블록으로 구성하여 추가
    final List<Map<String, dynamic>> currentUserContentBlocks = [];

    // 텍스트 메시지가 있을 경우 추가
    if (userMessageText.isNotEmpty) {
      currentUserContentBlocks.add({'type': 'text', 'text': userMessageText});
    }

    // 이미지 첨부파일 (Base64 방식)이 있을 경우 추가
    if (imageAttachmentsForClaude != null) {
      for (final imgAttach in imageAttachmentsForClaude) {
        currentUserContentBlocks.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': imgAttach['mime_type'],
            'data': base64Encode(imgAttach['bytes']),
          }
        });
      }
    }
    print("imageAttachmentsForClaude : ${imageAttachmentsForClaude}");
    print("claudeFileReferences : ${claudeFileReferences}");

    // 파일 첨부파일 (file_id 방식)이 있을 경우 추가
    if (claudeFileReferences != null) {
      for (final fileRef in claudeFileReferences) {
        // if (fileRef['type'] == 'image') {
        //   currentUserContentBlocks.add({
        //     'type': 'image',
        //     'source': {
        //       'type': 'file',
        //       'file_id': fileRef['file_id']!,
        //     },
        //   });
        // } else
          if (fileRef['type'] == 'document' || fileRef['type'] == 'pdf') {
          currentUserContentBlocks.add({
            'type': 'document',
            'source': {
              'type': 'file',
              'file_id': fileRef['file_id']!,
            },
          });
        }
      }
    }

    messagesForClaude.add({
      'role': 'user', // 사용자가 보낸 메시지이므로 항상 'user' 역할
      'content': currentUserContentBlocks,
    });

    // 이 부분에서 사용자 메시지를 DB에 저장할 수 있습니다.
    // ViewModel에서 이미 UI에 반영했으므로, DB 저장 로직은 여기로 옮겨 중복을 피할 수 있습니다.
    if (userMessageText.isNotEmpty) { // 파일은 이미 저장함
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        roomId: roomId,
        senderId: senderId,
        text: userMessageText,
        createdAt: DateTime.now(),
        type: imageAttachmentsForClaude != null
            ? 'image'
            : 'text', // 이미지가 있다면 타입 변경
      );
      await _chatRepository.sendMessage(userMessage);
      await _chatRepository.updateLastMessage(
          roomId, userMessageText, userMessage.createdAt);
    }

    String aiResponseText;
    try {
      aiResponseText = await _aiChatService.getResponse(messagesForClaude);
    } catch (e) {
      aiResponseText = 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})';
      print('[SendChatMessageUseCase] Failed to get Claude response: $e');
    }

    // 3. AI 메시지 생성 및 DB 저장
    final aiMessage = ChatMessage(
      id: const Uuid().v4(),
      roomId: roomId,
      senderId: AppConstants.aiSenderId,
      text: aiResponseText,
      createdAt: DateTime.now(),
      type: 'text',
    );
    await _chatRepository.sendMessage(aiMessage);
    await _chatRepository.updateLastMessage(roomId, aiResponseText, aiMessage.createdAt);

    return aiMessage;
  }
  // Future<ChatMessage> execute(
  //     String roomId,
  //     String senderId,
  //     String userMessageText,
  //     List<ChatMessage> currentMessagesForClaudeContext,
  //     {
  //       List<Map<String, String>>? claudeFileReferences,
  //       List<Map<String, dynamic>>? imageAttachmentsForClaude
  //     } // <- 이미지 첨부 데이터 추가
  //     ) async {
  //   final List<Map<String, dynamic>> chatHistoryForClaude = [];
  //
  //   // 기존 텍스트 메시지 및 (이미 바이트가 포함된) 이미지 메시지들을 Claude 포맷으로 변환
  //   for (final msg in currentMessagesForClaudeContext) {
  //     if (msg.senderId == 'OBOA' &&
  //         msg.text.contains('AI 응답을 가져오는 데 실패했습니다.')) {
  //       continue;
  //     }
  //
  //     if (msg.type == 'image' && msg.imageUrl != null &&
  //         msg.imageBytesForClaude != null) {
  //       // 이미지가 포함된 ChatMessage (재전송 시)
  //       chatHistoryForClaude.add({
  //         'role': msg.senderId == senderId ? 'user' : 'assistant',
  //         'content': [
  //           {'type': 'text', 'text': msg.text}, // 이미지에 대한 설명 텍스트
  //           {
  //             'type': 'image',
  //             'source': {
  //               'type': 'base64',
  //               'media_type': 'image/jpeg',
  //               // 실제 MIME 타입 (동적으로 가져와야 함)
  //               'data': base64Encode(msg.imageBytesForClaude!),
  //               // 이미지 바이트를 base64 인코딩
  //             }
  //           }
  //         ],
  //       });
  //     } else if (msg.claudeFileId != null && (msg.type == 'document' || msg.type == 'pdf')) {
  //       chatHistoryForClaude.add({
  //         'role': msg.senderId == senderId ? 'user' : 'assistant',
  //         'content': [
  //           {'type': 'text', 'text': msg.text}, // 관련 텍스트
  //           {
  //             'type': msg.type == 'image' ? 'image' : 'document', // content 블록 타입
  //             'source': {
  //               'type': 'file',
  //               'file_id': msg.claudeFileId!,
  //             },
  //           }
  //         ],
  //       });
  //     } else {
  //       // 일반 텍스트 메시지
  //       chatHistoryForClaude.add({
  //         'role': msg.senderId == senderId ? 'user' : 'assistant',
  //         'content': [{'type': 'text', 'text': msg.text}],
  //       });
  //     }
  //   }
  //
  //   // 현재 사용자 메시지 및 새로 첨부된 이미지를 Claude 포맷으로 추가
  //   final List<Map<String, dynamic>> currentUserContent = [];
  //   currentUserContent.add({'type': 'text', 'text': userMessageText});
  //
  //   // 새로 첨부된 이미지가 있다면 추가
  //   if (imageAttachmentsForClaude != null) {
  //     for (final imgAttach in imageAttachmentsForClaude) {
  //       currentUserContent.add({
  //         'type': 'image',
  //         'source': {
  //           'type': 'base64',
  //           'media_type': imgAttach['mime_type'], // 이미지 MIME 타입
  //           'data': base64Encode(imgAttach['bytes']), // 이미지 바이트
  //         }
  //       });
  //     }
  //   } else if (claudeFileReferences != null) {
  //     for (final fileRef in claudeFileReferences) {
  //       if (fileRef['type'] == 'image') {
  //         currentUserContent.add({
  //           'type': 'image',
  //           'source': {
  //             'type': 'file',
  //             'file_id': fileRef['file_id']!,
  //           },
  //         });
  //       } else if (fileRef['type'] == 'document' || fileRef['type'] == 'pdf') {
  //         currentUserContent.add({
  //           'type': 'document',
  //           'source': {
  //             'type': 'file',
  //             'file_id': fileRef['file_id']!,
  //           },
  //         });
  //       }
  //     }
  //   }
  //
  //   chatHistoryForClaude.add({
  //     'role': 'user',
  //     'content': currentUserContent, // 텍스트와 이미지를 포함한 content 배열
  //   });
  //
  //   print("chatHistoryForClaude :${chatHistoryForClaude}");
  //
  //   String aiResponseText;
  //   try {
  //
  //     aiResponseText = await _aiChatService.getResponse(
  //       userMessageText, // 현재 사용자 텍스트
  //       currentMessagesForClaudeContext, // 과거 메시지 기록
  //       claudeFileReferences, // <- Claude file_id 참조 전달
  //     );
  //     // Claude API 호출
  //     // aiResponseText = await _aiChatService.getClaudeResponse(chatHistoryForClaude);
  //   } catch (e) {
  //     // API 호출 자체가 실패한 경우, 오류 메시지를 응답으로 설정
  //     aiResponseText = 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})';
  //     print('[SendChatMessageUseCase] Failed to get Claude response: $e');
  //   }
  //
  //   // 3. AI 메시지 생성 및 DB 저장
  //   final aiMessage = ChatMessage(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID for now
  //     roomId: roomId,
  //     senderId: 'OBOA', // Or a dedicated AI ID
  //     text: aiResponseText,
  //     createdAt: DateTime.now(),
  //     type: 'text',
  //   );
  //   await _chatRepository.sendMessage(aiMessage);
  //   await _chatRepository.updateLastMessage(roomId, aiResponseText, aiMessage.createdAt);
  //
  //   return aiMessage; // <- AI 메시지 객체를 반환
  // }

  // AI 메시지 객체를 반환하도록 execute 메서드 시그니처 변경
  // Future<ChatMessage> execute(String roomId, String senderId, String messageText, List<ChatMessage> currentMessages) async {
  //   // 1. 사용자 메시지 생성 및 DB 저장
  //   final userMessage = ChatMessage(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID for now
  //     roomId: roomId,
  //     senderId: senderId,
  //     text: messageText,
  //     createdAt: DateTime.now(),
  //     type: 'text',
  //   );
  //   await _chatRepository.sendMessage(userMessage);
  //   await _chatRepository.updateLastMessage(roomId, messageText, userMessage.createdAt);
  //
  //   // 2. AI 응답을 위한 대화 기록 필터링 및 Claude API 호출
  //   // 현재 메시지 목록(currentMessages)에서 사용자 메시지를 포함한 모든 이전 메시지를 가져옵니다.
  //   // 실패 메시지는 API로 보내는 chatHistory에서 제외합니다.
  //   final chatHistoryForClaude = [userMessage, ...currentMessages].where((msg) { // <- 현재 사용자 메시지도 포함
  //     // AI 메시지 중 실패 메시지만 제외 (이전 실패 이력은 API에 보내지 않음)
  //     if (msg.senderId == 'OBOA' && msg.text.contains('AI 응답을 가져오는 데 실패했습니다.')) {
  //       return false;
  //     }
  //     return true;
  //   }).map((msg) { // Map ChatMessage 객체를 Claude API의 역할-콘텐츠 형식으로 변환
  //     return {
  //       'role': msg.senderId == senderId ? 'user' : 'assistant', // senderId는 현재 메시지 기준 사용자 ID
  //       'content': msg.text,
  //     };
  //   }).toList();
  //
  //   String aiResponseText;
  //   try {
  //     // Claude API 호출
  //     aiResponseText = await _aiChatService.getClaudeResponse(chatHistoryForClaude);
  //   } catch (e) {
  //     // API 호출 자체가 실패한 경우, 오류 메시지를 응답으로 설정
  //     aiResponseText = 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})';
  //     print('[SendChatMessageUseCase] Failed to get Claude response: $e');
  //   }
  //
  //   // 3. AI 메시지 생성 및 DB 저장
  //   final aiMessage = ChatMessage(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID for now
  //     roomId: roomId,
  //     senderId: 'OBOA', // Or a dedicated AI ID
  //     text: aiResponseText,
  //     createdAt: DateTime.now(),
  //     type: 'text',
  //   );
  //   await _chatRepository.sendMessage(aiMessage);
  //   await _chatRepository.updateLastMessage(roomId, aiResponseText, aiMessage.createdAt);
  //
  //   return aiMessage; // <- AI 메시지 객체를 반환
  // }

  // AI 메시지 객체를 반환하도록 execute 메서드 시그니처 변경
  // currentMessages는 Claude API에 보낼 문맥 정보 (사용자 메시지 전까지의 대화)
  // Future<ChatMessage> execute(String roomId, String senderId, String userMessageText, List<ChatMessage> currentMessagesForClaudeContext) async {
  //   // 1. 사용자 메시지 생성 (DB 저장은 ViewModel이 직접 하거나, 여기서 하면 됨 - 현재는 여기서 함)
  //   // ViewModel에서 userMessage를 먼저 UI에 보여주고 여기서 다시 DB에 저장하는 중복을 피하기 위해
  //   // ViewModel이 userMessage를 먼저 DB에 저장하고 UseCase로 넘겨주는 방식도 고려 가능.
  //   // 현재는 UseCase가 사용자 메시지 저장과 AI 메시지 저장을 모두 책임지도록 하겠습니다.
  //
  //   // 2. AI 응답을 위한 대화 기록 필터링 및 Claude API 호출
  //   // Claude API에 보낼 대화 기록을 필터링합니다.
  //   // "AI 응답을 가져오는 데 실패했습니다."와 같은 메시지는 제외하고,
  //   // UseCase로 넘어온 currentMessagesForClaudeContext에 userMessageText를 추가하여 보냅니다.
  //
  //   final chatHistoryForClaude = currentMessagesForClaudeContext.where((msg) {
  //     if (msg.senderId == 'OBOA' && msg.text.contains('AI 응답을 가져오는 데 실패했습니다.')) {
  //       return false;
  //     }
  //     return true;
  //   }).map((msg) {
  //     return {
  //       'role': msg.senderId == senderId ? 'user' : 'assistant',
  //       'content': msg.text,
  //     };
  //   }).toList();
  //
  //   // 현재 사용자 메시지를 대화 기록에 추가
  //   chatHistoryForClaude.add({
  //     'role': 'user',
  //     'content': userMessageText,
  //   });
  //
  //   String aiResponseText;
  //   try {
  //     aiResponseText = await _aiChatService.getClaudeResponse(chatHistoryForClaude);
  //   } catch (e) {
  //     aiResponseText = 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})';
  //     print('[SendChatMessageUseCase] Failed to get Claude response: $e');
  //   }
  //
  //   // 3. AI 메시지 생성 및 DB 저장
  //   final aiMessage = ChatMessage(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     roomId: roomId,
  //     senderId: 'OBOA',
  //     text: aiResponseText,
  //     createdAt: DateTime.now(),
  //     type: 'text',
  //   );
  //   await _chatRepository.sendMessage(aiMessage); // <- AI 메시지 DB 저장
  //   await _chatRepository.updateLastMessage(roomId, aiResponseText, aiMessage.createdAt);
  //
  //   return aiMessage; // <- AI 메시지 객체를 반환
  // }

  // Future<ChatMessage> execute(String roomId, String senderId, String userMessageText, List<ChatMessage> currentMessagesForClaudeContext) async {
    // 1. 사용자 메시지 생성 및 DB 저장 (ViewModel이 사용자 메시지를 먼저 UI에 보여줬을 수 있음)
    // 여기서는 ViewModel에서 UI에 반영한 사용자 메시지를 다시 DB에 저장하는 중복을 피하기 위해
    // ViewModel이 userMessage를 먼저 DB에 저장하고 UseCase를 호출하는 방식으로 가정하겠습니다.
    // 만약 ViewModel이 DB 저장까지 UseCase에 위임한다면 아래 코드를 활성화해야 합니다.
    /*
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: senderId,
      text: userMessageText,
      createdAt: DateTime.now(),
      type: 'text',
    );
    await _chatRepository.sendMessage(userMessage);
    await _chatRepository.updateLastMessage(roomId, userMessageText, userMessage.createdAt);
    */

    // 2. AI 응답을 위한 대화 기록 필터링 및 Claude API 호출
    // Claude API에 보낼 대화 기록을 필터링합니다.
    // "AI 응답을 가져오는 데 실패했습니다."와 같은 메시지는 제외하고,
    // UseCase로 넘어온 currentMessagesForClaudeContext에 userMessageText를 추가하여 보냅니다.

  //   final chatHistoryForClaude = currentMessagesForClaudeContext.where((msg) {
  //     if (msg.senderId == 'OBOA' && msg.text.contains('AI 응답을 가져오는 데 실패했습니다.')) {
  //       return false;
  //     }
  //     return true;
  //   }).map((msg) {
  //     return {
  //       'role': msg.senderId == senderId ? 'user' : 'assistant',
  //       'content': msg.text,
  //     };
  //   }).toList();
  //
  //   // 현재 사용자 메시지를 대화 기록에 추가
  //   chatHistoryForClaude.add({
  //     'role': 'user',
  //     'content': userMessageText,
  //   });
  //
  //   String aiResponseText;
  //   try {
  //     aiResponseText = await _aiChatService.getClaudeResponse(chatHistoryForClaude);
  //   } catch (e) {
  //     aiResponseText = 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})';
  //     print('[SendChatMessageUseCase] Failed to get Claude response: $e');
  //   }
  //
  //   // 3. AI 메시지 생성 및 DB 저장
  //   final aiMessage = ChatMessage(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     roomId: roomId,
  //     senderId: 'OBOA',
  //     text: aiResponseText,
  //     createdAt: DateTime.now(),
  //     type: 'text',
  //   );
  //   await _chatRepository.sendMessage(aiMessage); // <- AI 메시지 DB 저장
  //   await _chatRepository.updateLastMessage(roomId, aiResponseText, aiMessage.createdAt);
  //
  //   return aiMessage; // <- AI 메시지 객체를 반환
  // }
}