import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';

import '../model/chat_room.dart';
import '../repository/chat_repository.dart';

class CreateOrGetAIChatRoomUseCase {
  final ChatRepository _chatRepository;

  CreateOrGetAIChatRoomUseCase({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  Future<ChatRoom> execute(String userId) async {
    List<ChatRoom> rooms = await _chatRepository.getChatRooms(userId);
    ChatRoom? aiRoom = rooms.firstWhereOrNull(
            (room) => room.type == 'ai_chat' && room.creatorId == userId); // Or a global AI room

    if (aiRoom == null) {
      aiRoom = await _chatRepository.createChatRoom(
        'OBOA AI Chat',
        'ai_chat',
        creatorId: userId,
      );
      // --- 새로 생성된 채팅방에 초기 메시지 보내기 ---
      final initialMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: aiRoom.id,
        senderId: AppConstants.aiSenderId, // AI의 senderId
        text: '너의 이름이 뭔지 알려줄수 있어?\n(이름은 나중에 변경하실 수 있습니다.)',
        createdAt: DateTime.now(),
        type: 'text',
      );

      await _chatRepository.sendMessage(initialMessage);
      await _chatRepository.updateLastMessage(aiRoom.id, initialMessage.text, initialMessage.createdAt);
    }
    print("CreateOrGetAIChatRoomUseCase execute aiRoom result ${aiRoom}");
    return aiRoom;
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}