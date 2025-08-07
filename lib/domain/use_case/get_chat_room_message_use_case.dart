import '../model/chat_message.dart';
import '../repository/chat_repository.dart';

class GetChatRoomMessagesUseCase {
  final ChatRepository _chatRepository;

  GetChatRoomMessagesUseCase({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  Stream<List<ChatMessage>> execute(String roomId) {
    return _chatRepository.getMessagesForRoom(roomId);
  }
}