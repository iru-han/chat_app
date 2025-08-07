import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/model/chat_message.dart';
import '../../../domain/model/chat_room.dart';

class SupabaseChatDataSource {
  final SupabaseClient _supabase;

  SupabaseChatDataSource(this._supabase);

  // 내가 속해있는 방 목록 가져오기
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    // chat_room_members 테이블을 조인하여 현재 userId가 속한 모든 room_id를 가져온다.
    final List<dynamic> roomMemberships = await _supabase
        .from('chat_room_members')
        .select('room_id')
        .eq('user_id', userId);

    final List<String> roomIds = roomMemberships
        .map((member) => member['room_id'] as String)
        .toList();

    if (roomIds.isEmpty) {
      return [];
    }

    // room_id 리스트를 사용하여 chat_rooms 테이블에서 해당 방들을 가져온다.
    final List<dynamic> response = await _supabase
        .from('chat_rooms')
        .select('*')
        .inFilter('id', roomIds)
        .order('id');

    return response.map((json) => ChatRoom.fromJson(json)).toList();
  }

  // 채팅방 가져오기
  Future<ChatRoom?> getChatRoom(String roomId) async {
    final response = await _supabase.from('chat_rooms').select('*').eq('id', roomId).single();
    return ChatRoom.fromJson(response);
  }

  Future<ChatRoom> createChatRoom(String name, String type, {String? creatorId}) async {
    // 1. 새로운 채팅방 생성
    final response = await _supabase
        .from('chat_rooms')
        .insert({
        'name': name ?? '새로운 대화방',
        'type': 'ai_chat', // AI와의 대화방이므로 'ai_chat'으로 설정
        'creator_id': creatorId,
      })
        .select() // 생성된 방의 id만 가져옴
        .single(); // 하나의 레코드만 반환
    print("createChatRoom response ${response}");

    final roomId = response['id'] as String;

    // 2. 방 생성자를 chat_room_members에 추가
    final chatRoomMembers = await _supabase
        .from('chat_room_members')
        .insert({
      'room_id': roomId,
      'user_id': creatorId,
      'is_admin': true, // 방 생성자는 관리자로 설정
    })
        .select() // 생성된 방의 id만 가져옴
        .single();

    print("createChatRoom chatRoomMembers ${chatRoomMembers}");
    return ChatRoom.fromJson(response);
  }

  Stream<List<ChatMessage>> getMessagesForRoom(String roomId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  Future<void> sendMessage(ChatMessage message) async {
    var insertData = {
      // 'id': message.id,
      'room_id': message.roomId,
      'sender_id': message.senderId,
      'text': message.text,
      'created_at': message.createdAt.toIso8601String(),
      'type': message.type,
      'image_url': message.imageUrl,
      'file_url': message.fileUrl,
      'file_name': message.fileName,
      'claude_file_id': message.claudeFileId,
    };
    print("execute insertData: ${insertData}");
    await _supabase.from('chat_messages').insert(insertData);
  }

  Future<void> updateLastMessage(String roomId, String messageText, DateTime messageTime) async {
    await _supabase.from('chat_rooms').update({
      'last_message_text': messageText,
      'last_message_at': messageTime.toIso8601String(),
    }).eq('id', roomId);
  }
}