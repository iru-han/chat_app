import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/core/presentation/components/build_selected_attachments_preview.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_capture_content.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_header.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_input.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_list_view.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_popup_menu.dart';
import 'package:oboa_chat_app/core/presentation/components/share_capture_buttons.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/attachment_options_dialog.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/share_dialog.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/capture_options_dialog.dart'; // 캡쳐 옵션 다이얼로그 추가
import 'package:oboa_chat_app/core/presentation/dialogs/share_dialog_content.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../chat_action.dart';
import '../chat_state.dart';
import '../chat_view_model.dart'; // ViewModel import

// !!! 추가 import: RepaintBoundary와 RenderRepaintBoundary를 위해 !!!
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui; // ui.Image를 위해

enum ChatMenu {
  share,
  capture,
}

class ChatScreen extends StatelessWidget {
  final ChatState state;
  final void Function(ChatAction action) onAction;
  final void Function(ChatMenu menu) onTapMenu; // 현재는 사용 안함 (직접 액션 호출로 변경)
  final ChatViewModel viewModel;
  final TextEditingController messageInputController; // <- 컨트롤러를 직접 받도록 변경
  final ScrollController chatListScrollController; // <- 스크롤 컨트롤러를 직접 받도록 변경

  ChatScreen({
    super.key,
    required this.state,
    required this.onAction,
    required this.onTapMenu, // 현재 onTapMenu는 PopupMenuButton에서만 사용
    required this.viewModel,
    required this.messageInputController,
    required this.chatListScrollController,
  });

  // 캡처할 RepaintBoundary에 연결할 새로운 GlobalKey
  // 이 Key는 선택 영역 캡처 시 동적으로 생성될 RepaintBoundary에 사용됩니다.
  final GlobalKey _captureSelectedAreaKey = GlobalKey();

  // 스크롤 로직
  void _scrollToBottom() {
    if (chatListScrollController.hasClients) {
      chatListScrollController.jumpTo(chatListScrollController.position.maxScrollExtent);
      chatListScrollController.animateTo(
        chatListScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      ).then((_) {
        onAction(const ChatAction.resetScrollState());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. 새로운 메시지가 추가되었을 때만 스크롤을 내리도록 `addPostFrameCallback` 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.isNewMessageAdded) {
        _scrollToBottom();
      }
    });

    if (state.tempImagePath != null) {
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
        // ⭐ 다이얼로그를 띄운 후, 상태를 초기화하여 중복 실행 방지
        onAction(const ChatAction.clearTempImagePath());
      });
    }

    // ViewModel의 상태와 TextField 컨트롤러의 텍스트가 다르면 동기화
    if (messageInputController.text != state.currentInputText) {
      // 텍스트를 업데이트하고 커서를 끝으로 이동
      messageInputController.value = messageInputController.value.copyWith(
        text: state.currentInputText,
        selection: TextSelection.collapsed(offset: state.currentInputText.length),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack( // 팝업 오버레이를 위해 Stack 사용
          children: [
            Column(
              children: [
                Stack(
                  children: [
                    ChatHeader(
                        imageUrl: AppConstants.aiProfileImagePath, // 프로필 이미지로 변경해야 함
                        text: state.currentChatRoom?.name ?? AppConstants.aiSenderId, // 대화 상대명으로 변경해야 함
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
                    color: ColorStyles.primary.withOpacity(0.1), // 배경색
                    child: Text(
                      '공유할 대화의 시작과 끝을 선택해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyles.smallTextRegular.copyWith(color: ColorStyles.primary),
                    ),
                  ),
                Expanded(
                  child: ChatListView( // <- 새로운 위젯 사용
                    chatListScrollController: chatListScrollController,
                    state: state,
                    onAction: onAction,
                  ),
                ),
                // 선택된 첨부 파일 프리뷰 영역
                if (state.selectedAttachments.isNotEmpty)
                  SelectedAttachmentsPreview(
                    attachments: state.selectedAttachments,
                    onAction: onAction,
                  ),

                // 하단 입력창 또는 공유/캡쳐 모드 버튼
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
            // 팝업 오버레이
            if (state.showCaptureOptionsDialogPopup) _buildCaptureOptionsDialog(context),

            // 팝업 배경 오버레이를 먼저 렌더링
            if (state.showPopupMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    onAction(const ChatAction.hidePopupMenu());
                  },
                ),
              ),

            // 팝업 메뉴를 가장 마지막에 렌더링
            if (state.showPopupMenu)
              ChatPopupMenu(onAction: onAction),
            // !!! 변경된 부분: 선택 영역 오버레이 !!!
            // if (state.isInShareCaptureMode)
            //   _buildSelectionOverlay(context), // <- 선택 모드일 때 오버레이 표시
          ],
        ),
      ),
    );
  }


  Future<void> _performCaptureAndShare(BuildContext context, Widget widgetToCapture) async {
    OverlayEntry? captureOverlayEntry;
    String? lastCapturedImagePath; // 캡처된 이미지 경로

    try {

      final String? startMessageId = state.shareRangeStartMessageId;
      final String? endMessageId = state.shareRangeEndMessageId;
      if (startMessageId == null) {
        throw Exception('캡처할 메시지 범위를 선택해주세요.');
      }

      final startIndex = state.messages.indexWhere((msg) => msg.id == startMessageId);
      final endIndex = state.messages.indexWhere((msg) => msg.id == endMessageId);

      int effectiveStartIndex = min(startIndex, endIndex);
      int effectiveEndIndex = max(startIndex, endIndex);

      if (startIndex == -1) {
        throw Exception('캡처할 메시지를 찾을 수 없습니다.');
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

      // 캡처할 위젯을 Overlay에 잠시 띄워 렌더링되도록 합니다.
      captureOverlayEntry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          left: -100000.0, // 화면 밖으로 멀리 보내 보이지 않게 렌더링
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
        throw Exception("캡처 대상 위젯이 레이아웃되지 않았습니다 (hasSize: false).");
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("이미지 데이터를 얻을 수 없습니다.");
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      // // ⭐ 캡처된 바이트 데이터를 ViewModel에 전달 (로직 간소화)
      // onAction(ChatAction.handleCapturedImage(pngBytes));
      // // onAction 호출 후 캡처 모드를 바로 종료
      // onAction(const ChatAction.exitShareCaptureMode());

      final directory = await getTemporaryDirectory();
      final String tempFileName = "share_capture_${DateTime.now().millisecondsSinceEpoch}.png";
      final File tempFile = File('${directory.path}/$tempFileName');
      await tempFile.writeAsBytes(pngBytes);
      lastCapturedImagePath = tempFile.path;

      // 캡처된 이미지 경로를 ViewModel에 전달하여 공유 액션 수행
      if (lastCapturedImagePath != null) {
        onAction(ChatAction.shareFile(lastCapturedImagePath!, text: '채팅 화면을 공유합니다!'));

        // showModalBottomSheet(
        //   context: context,
        //   // isScrollControlled: true를 설정하면 바텀시트가 화면 전체를 덮을 수 있습니다.
        //   // isDismissible: true는 기본값으로, 바텀시트 외부를 탭하면 닫힙니다.
        //   // barrierColor: Colors.black.withOpacity(0.5)로 설정하여 배경색을 동일하게 유지할 수 있습니다.
        //   builder: (BuildContext context) {
        //     return ShareDialogContent(
        //       state: state,
        //       onAction: onAction,
        //     );
        //   },
        // );
      } else {
        throw Exception("캡처된 이미지 경로를 얻지 못해 공유할 수 없습니다.");
      }

    } catch (e) {
      print('Error during capture and share: $e');
      onAction(ChatAction.clearShareRangeSelection());
      // onAction(ChatAction.setError(e.toString()));
    } finally {
      captureOverlayEntry?.remove();
      captureOverlayEntry = null;
      // onAction(const ChatAction.setLoading(false));
      onAction(const ChatAction.exitShareCaptureMode());
    }
  }

  // 캡쳐 옵션 다이얼로그 오버레이
  Widget _buildCaptureOptionsDialog(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => onAction(const ChatAction.hideCaptureOptionsDialog()), // 팝업 바깥 탭 시 닫기
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

}