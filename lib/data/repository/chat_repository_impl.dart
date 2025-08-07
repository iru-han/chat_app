import 'package:oboa_chat_app/data/data_source/supabase_chat_data_source.dart';

import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_room.dart';
import '../../domain/repository/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseChatDataSource _dataSource;

  ChatRepositoryImpl({required SupabaseChatDataSource dataSource}) : _dataSource = dataSource;

  @override
  Future<List<ChatRoom>> getChatRooms(String userId) {
    return _dataSource.getChatRooms(userId);
  }

  @override
  Future<ChatRoom?> getChatRoom(String roomId) {
    return _dataSource.getChatRoom(roomId);
  }

  @override
  Future<ChatRoom> createChatRoom(String name, String type, {String? creatorId}) {
    return _dataSource.createChatRoom(name, type, creatorId: creatorId);
  }

  @override
  Stream<List<ChatMessage>> getMessagesForRoom(String roomId) {
    return _dataSource.getMessagesForRoom(roomId);
  }

  @override
  Future<void> sendMessage(ChatMessage message) {
    return _dataSource.sendMessage(message);
  }

  @override
  Future<void> updateLastMessage(String roomId, String messageText, DateTime messageTime) {
    return _dataSource.updateLastMessage(roomId, messageText, messageTime);
  }
}