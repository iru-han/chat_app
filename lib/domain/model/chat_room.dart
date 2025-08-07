import 'package:freezed_annotation/freezed_annotation.dart'; // freezed 관련
import 'package:json_annotation/json_annotation.dart';     // @JsonKey 관련

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String id,
    required String name,
    required String type,

    // createdAt 필드 위에 @JsonKey(name: 'created_at') 붙이기
    @JsonKey(name: 'created_at')
    required DateTime createdAt,

    // lastMessageAt 필드 위에 @JsonKey(name: 'last_message_at', ...) 붙이기
    @JsonKey(
      name: 'last_message_at',
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    )
    DateTime? lastMessageAt,

    // lastMessageText 필드 위에 @JsonKey(name: 'last_message_text') 붙이기
    @JsonKey(
      name: 'last_message_text',
    )
    String? lastMessageText,

    // creatorId 필드 위에 @JsonKey(name: 'creator_id') 붙이기
    @JsonKey(name: 'creator_id')
    String? creatorId,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, Object?> json) => _$ChatRoomFromJson(json);
}

// fromJson/toJson 헬퍼 함수들은 그대로 유지 (필드 밖, 파일 내 아무 곳이나)
DateTime? _dateTimeFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  return DateTime.parse(json as String);
}

Object? _dateTimeToJson(DateTime? dateTime) {
  return dateTime?.toIso8601String();
}