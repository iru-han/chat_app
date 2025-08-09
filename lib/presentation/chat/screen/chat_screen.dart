import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/core/presentation/components/build_selected_attachments_preview.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_capture_content.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_header.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_input.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_list_view.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_popup_menu.dart';
import 'package:oboa_chat_app/core/presentation/components/share_capture_buttons.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/capture_options_dialog.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/share_dialog_content.dart';


class ChatScreen extends StatelessWidget {
  final ChatState state;
  final void Function(ChatAction action) onAction;
  final TextEditingController messageInputController;
  final ScrollController chatListScrollController;

  ChatScreen({
    super.key,
    required this.state,
    required this.onAction,
    required this.messageInputController,
    required this.chatListScrollController,
  });

  // 캡처할 RepaintBoundary에 연결할 GlobalKey
  final GlobalKey _captureSelectedAreaKey = GlobalKey();

  // 캡처 후 공유 로직
  Future<void> _performCaptureAndShare(BuildContext context, Widget widgetToCapture) async {
    OverlayEntry? captureOverlayEntry;

    try {
      final String? startMessageId = state.shareRangeStartMessageId;
      final String? endMessageId = state.shareRangeEndMessageId;
      if (startMessageId == null) {
        onAction(const ChatAction.exitShareCaptureMode());
        return;
      }

      final startIndex = state.messages.indexWhere((msg) => msg.id == startMessageId);
      final endIndex = state.messages.indexWhere((msg) => msg.id == endMessageId);

      int effectiveStartIndex = min(startIndex, endIndex);
      int effectiveEndIndex = max(startIndex, endIndex);

      if (startIndex == -1) {
        onAction(const ChatAction.exitShareCaptureMode());
        return;
      }
      if (endMessageId == null || endIndex == -1) {
        effectiveEndIndex = startIndex;
      }

      final List<ChatMessage> messagesToCapture = [];
      for (int i = 0; i < state.messages.length; i++) {
        if (i >= effectiveStartIndex && i <= effectiveEndIndex) {
          messagesToCapture.add(state.messages[i]);
        }
      }

      captureOverlayEntry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          left: -100000.0,
          top: -100000.0,
          child: RepaintBoundary(
            key: _captureSelectedAreaKey,
            child: widgetToCapture,
          ),
        ),
      );

      Navigator.of(context).overlay?.insert(captureOverlayEntry);
      await Future.delayed(const Duration(milliseconds: 100));

      final RenderRepaintBoundary boundary = _captureSelectedAreaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      if (!boundary.hasSize) {
        onAction(const ChatAction.exitShareCaptureMode());
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        onAction(const ChatAction.exitShareCaptureMode());
        return;
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();

      onAction(ChatAction.handleCapturedImage(pngBytes));

    } catch (e) {
      print('Error during capture and share: $e');
      onAction(ChatAction.exitShareCaptureMode());
    } finally {
      captureOverlayEntry?.remove();
    }
  }

  // 캡쳐 옵션 다이얼로그
  Widget _buildCaptureOptionsDialog(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => onAction(const ChatAction.hideCaptureOptionsDialog()),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: CaptureOptionsDialog(
              maskProfile: state.maskProfile,
              maskBotName: state.maskBotName,
              maskBackground: state.maskBackground,
              onToggleProfile: (value) => onAction(ChatAction.setProfileMasking(value)),
              onToggleBotName: (value) => onAction(ChatAction.setBotNameMasking(value)),
              onToggleBackground: (value) => onAction(ChatAction.setBackgroundMasking(value)),
              onConfirm: () {
                onAction(const ChatAction.confirmCaptureOptions());
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel의 상태와 TextField 컨트롤러의 텍스트 동기화
    if (messageInputController.text != state.currentInputText) {
      messageInputController.value = messageInputController.value.copyWith(
        text: state.currentInputText,
        selection: TextSelection.collapsed(offset: state.currentInputText.length),
      );
    }

    // 스크롤 로직을 build 메서드에서 직접 호출
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (state.isNewMessageAdded) {
        if (chatListScrollController.hasClients) {
          chatListScrollController.jumpTo(chatListScrollController.position.maxScrollExtent);
        }
        onAction(const ChatAction.resetScrollState());
      }
    });

    // 캡처 이미지 URL이 있을 때 공유 다이얼로그 띄우기
    if (state.supabaseImageUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return ShareDialogContent(
              state: state,
              onAction: onAction,
            );
          },
        );
        // onAction(const ChatAction.setSupabaseImageUrl(null));
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Stack(
                  children: [
                    ChatHeader(
                        imageUrl: AppConstants.aiProfileImagePath,
                        text: state.currentChatRoom?.name ?? AppConstants.aiSenderId,
                        goBack: () {},
                        onPressSetting: () {}
                    ),
                    if (state.isInShareCaptureMode)
                      Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                          )
                      )
                  ],
                ),
                if (state.isInShareCaptureMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    color: ColorStyles.primary.withOpacity(0.1),
                    child: Text(
                      '공유할 대화의 시작과 끝을 선택해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyles.smallTextRegular.copyWith(color: ColorStyles.primary),
                    ),
                  ),
                Expanded(
                  child: ChatListView(
                    chatListScrollController: chatListScrollController,
                    state: state,
                    onAction: onAction,
                  ),
                ),
                if (state.selectedAttachments.isNotEmpty)
                  SelectedAttachmentsPreview(
                    attachments: state.selectedAttachments,
                    onAction: onAction,
                  ),
                if (state.isInShareCaptureMode)
                  ShareCaptureButtons(
                    state: state,
                    onAction: onAction,
                    onConfirmAndCapture: _performCaptureAndShare,
                    messages: state.messages,
                  )
                else
                  ChatInput(
                    state: state,
                    onAction: onAction,
                    messageInputController: messageInputController,
                  ),
              ],
            ),
            if (state.showCaptureOptionsDialogPopup) _buildCaptureOptionsDialog(context),
            if (state.showPopupMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    onAction(const ChatAction.hidePopupMenu());
                  },
                ),
              ),
            if (state.showPopupMenu) ChatPopupMenu(onAction: onAction),
          ],
        ),
      ),
    );
  }

}