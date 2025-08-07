import '../model/chat_message.dart';
import '../model/chat_room.dart';

abstract interface class ChatRepository {
  Future<List<ChatRoom>> getChatRooms(String userId);
  Future<ChatRoom?> getChatRoom(String roomId);
  Future<ChatRoom> createChatRoom(String name, String type, {String? creatorId});
  Stream<List<ChatMessage>> getMessagesForRoom(String roomId);
  Future<void> sendMessage(ChatMessage message);
  Future<void> updateLastMessage(String roomId, String messageText, DateTime messageTime);
}