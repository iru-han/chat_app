import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'room_id') required String roomId,
    @JsonKey(name: 'sender_id') required String senderId, // Can be user ID or 'AI'
    required String text,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default('text') String type,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'file_url') String? fileUrl,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'claude_file_id') String? claudeFileId,
    @JsonKey(includeFromJson: false) // DB에 저장하지 않음
    Uint8List? imageBytesForClaude // <- Claude에 보낼 임시 이미지 바이트
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, Object?> json) => _$ChatMessageFromJson(json);
}