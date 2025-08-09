import 'package:freezed_annotation/freezed_annotation.dart'; // freezed 관련
import 'package:json_annotation/json_annotation.dart';     // @JsonKey 관련

part 'chat_room_share.freezed.dart';
part 'chat_room_share.g.dart';

@freezed
class ChatRoomShare with _$ChatRoomShare {
  const factory ChatRoomShare({
    required String id,

    // roomId 필드 위에 @JsonKey(name: 'room_id') 붙이기
    @JsonKey(name: 'room_id')
    required String roomId,

    // userId 필드 위에 @JsonKey(name: 'user_id') 붙이기
    @JsonKey(name: 'user_id')
    required String userId,

    // imageUrl 필드 위에 @JsonKey(name: 'image_url') 붙이기
    @JsonKey(name: 'image_url')
    required String imageUrl,

    // createdAt 필드 위에 @JsonKey(name: 'created_at') 붙이기
    @JsonKey(name: 'created_at')
    required DateTime createdAt,
  }) = _ChatRoomShare;

  factory ChatRoomShare.fromJson(Map<String, Object?> json) => _$ChatRoomShareFromJson(json);
}