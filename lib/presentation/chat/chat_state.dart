import 'dart:typed_data';

import 'package:oboa_chat_app/domain/model/selected_attachment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_room.dart';

import 'package:flutter/material.dart';
part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    ChatRoom? currentChatRoom,
    @Default([]) List<ChatMessage> messages,
    @Default('') String currentInputText,
    @Default(false) bool isListening,

    // 변경된 상태 변수들
    @Default(false) bool showPopupMenu, // '캡쳐옵션' 버튼 클릭 시 뜨는 팝업
    @Default(false) bool showShareDialogPopup, // '+' 버튼 클릭 시 뜨는 공유 팝업 (URL 복사 등)
    @Default(false) bool isInShareCaptureMode, // 하단 '공유하기' 버튼 클릭 시 진입하는 모드
    @Default(false) bool showCaptureOptionsDialogPopup, // '캡쳐옵션' 버튼 클릭 시 뜨는 팝업

    @Default(false) bool maskProfile,
    @Default(false) bool maskBotName,
    @Default(false) bool maskBackground,

    String? shareRangeStartMessageId, // 시작 메시지 ID
    String? shareRangeEndMessageId,   // 끝 메시지 ID
    @Default(false) bool isLoading,
    String? errorMessage,
    String? currentUserId,
    @Default(false) bool showAttachmentOptionsDialog, // <- 새롭게 추가할 파일/이미지 선택 옵션 팝업
    @Default([]) List<SelectedAttachment> selectedAttachments,
    String? tempImagePath,
    Uint8List? capturedBytes, // <- New: Stores the bytes of the captured preview image
    @Default({}) Set<String> revealedMessageIds, // <- 새로 추가: 오버레이가 사라질 메시지 ID 목록
    @Default(false) bool isNewMessageAdded, // 메시지 추가 여부 - 스크롤 위해

    String? supabaseImageUrl, // 추가
    String? shareUrl, // 추가
  }) = _ChatState;
}