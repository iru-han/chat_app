// lib/domain/model/selected_attachment.dart
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_attachment.freezed.dart';
part 'selected_attachment.g.dart';

@freezed
@JsonSerializable()
class SelectedAttachment with _$SelectedAttachment {
  const factory SelectedAttachment({
    required String id, // UI 관리를 위한 고유 ID
    required String path, // 원본 파일 경로
    required String name, // 파일 이름 (확장자 포함)
    @Default('') String mimeType, // 이미지 mimeType, 클로드에 보내기위해
    required String type, // 'image', 'video', 'file' 등
    @JsonKey(includeFromJson: false)
    Uint8List? bytes, // 미리보기나 업로드를 위한 바이트 데이터 (선택 사항, 대용량 파일은 경로만)
    String? previewUrl, // 이미지 미리보기 (로컬 경로 또는 base64)
  }) = _SelectedAttachment;
}