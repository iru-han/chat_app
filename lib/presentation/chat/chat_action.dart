import 'dart:typed_data';

import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/domain/model/selected_attachment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'chat_action.freezed.dart';

@freezed
sealed class ChatAction with _$ChatAction {
  const factory ChatAction.loadChatRoom(String? roomId) = LoadChatRoom;
  const factory ChatAction.startListening() = StartListening;
  const factory ChatAction.stopListening() = StopListening;
  const factory ChatAction.updateTranscription(String text) = UpdateTranscription;

  const factory ChatAction.showPopupMenu() = ShowPopupMenu;
  const factory ChatAction.hidePopupMenu() = HidePopupMenu;

  // 기존 ToggleShareOptions는 "공유 팝업"을 띄우는 역할로 변경 (TextField 옆의 + 버튼)
  const factory ChatAction.showShareDialog() = ShowShareDialog;
  const factory ChatAction.hideShareDialog() = HideShareDialog; // ShareDialog 닫기

  // 새로운 캡쳐/공유 모드 진입/나가기 액션
  const factory ChatAction.enterShareCaptureMode() = EnterShareCaptureMode;
  const factory ChatAction.exitShareCaptureMode() = ExitShareCaptureMode;

  const factory ChatAction.showCaptureOptionsDialog() = ShowCaptureOptionsDialog; // 캡쳐옵션 팝업 띄우기
  const factory ChatAction.hideCaptureOptionsDialog() = HideCaptureOptionsDialog; // 캡쳐옵션 팝업 닫기

  const factory ChatAction.setProfileMasking(bool value) = SetProfileMasking;
  const factory ChatAction.setBotNameMasking(bool value) = SetBotNameMasking;
  const factory ChatAction.setBackgroundMasking(bool value) = SetBackgroundMasking;
  const factory ChatAction.confirmCaptureOptions() = ConfirmCaptureOptions;

  const factory ChatAction.copyShareLink(String link) = CopyShareLink;

  // 대화 범위 선택 (선택된 메시지를 위해 ChatMessage ID나 Index를 받는 것이 더 유연)
  const factory ChatAction.selectMessageForShare(String messageId) = SelectMessageForShare;
  const factory ChatAction.clearShareRangeSelection() = ClearShareRangeSelection;
  const factory ChatAction.confirmShareSelection() = ConfirmShareSelection; // 하단 공유 버튼 클릭

  const factory ChatAction.pickImage() = PickImage; // 이미지 선택 액션
  const factory ChatAction.pickFile() = PickFile;   // 파일 선택 액션
  const factory ChatAction.sendFileMessage(String url, String fileName, String type) = SendFileMessage; // 파일/이미지 메시지 전송 액션

  // 파일/이미지 선택 후 선택 목록에 추가
  const factory ChatAction.addSelectedAttachment(SelectedAttachment attachment) = AddSelectedAttachment;
  const factory ChatAction.removeSelectedAttachment(String attachmentId) = RemoveSelectedAttachment;

  // 메시지 전송 시 첨부 파일도 함께 전송
  const factory ChatAction.sendChatMessageWithAttachments(String text, List<SelectedAttachment> attachments) = SendChatMessageWithAttachments;

  const factory ChatAction.shareCapturedImage(String imagePath) = ShareCapturedImage; // <- 캡처 이미지 공유 액션

  const factory ChatAction.shareCapturedImageToInstagram(String imagePath) = ShareCapturedImageToInstagram;
  const factory ChatAction.shareCapturedImageToX(String imagePath) = ShareCapturedImageToX;
  const factory ChatAction.shareCapturedImageToKakaoTalk(String imagePath) = ShareCapturedImageToKakaoTalk;
  const factory ChatAction.shareCapturedImageToFacebook(String imagePath) = ShareCapturedImageToFacebook;

  // 모든 공유를 아우르는 제너릭 액션 (혹은 위 개별 액션들을 그대로 사용)
  const factory ChatAction.shareFile(String filePath, {String? text, String? subject}) = ShareFile;
  const factory ChatAction.clearError() = ClearError;
  // 새 액션: View에서 캡처된 이미지 바이트를 ViewModel로 전달
  const factory ChatAction.handleCapturedImage(Uint8List? bytes) = HandleCapturedImage;

  const factory ChatAction.resetScrollState() = ResetScrollState;
  const factory ChatAction.setTempImagePath(String? path) = SetTempImagePath;
  const factory ChatAction.clearTempImagePath() = ClearTempImagePath;

  const factory ChatAction.setSupabaseImageUrl(String? url) = SetSupabaseImageUrl;
  const factory ChatAction.generateShareUrl(String? imageUrl, String? deepLink) = GenerateShareUrl;
  const factory ChatAction.shareToTwitter(String url) = ShareToTwitter;
}