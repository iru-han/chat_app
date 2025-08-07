// chat_message_item.dart
import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

import 'chat_bubble.dart';

// 필요한 다른 위젯과 모델 가져오기

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final int messageIndex;
  final ChatState state;
  final Function(ChatAction)? onAction; // 캡처 모드에서는 사용하지 않으므로 nullable로 변경
  final bool forCapture; // 이 변수로 캡처 모드인지 아닌지 구분

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.messageIndex,
    required this.state,
    required this.onAction,
    this.forCapture = false, // 기본값은 false로 설정
  });

  bool shouldShowTimestamp(ChatMessage currentMessage, ChatMessage? previousMessage) {
    if (previousMessage == null) return true;
    return currentMessage.createdAt.difference(previousMessage.createdAt).inMinutes > 60;
  }

  String formatTimestamp(DateTime timestamp) {
    // 타임스탬프 포맷팅 로직
    return '${timestamp.hour}:${timestamp.minute}';
  }

  bool isOverlay(String messageId, ChatState state) {
    // 오버레이 로직
    // 예시: 공유 캡처 모드에서만 오버레이 표시
    if (!state.isInShareCaptureMode) return false;
    // 실제 로직을 여기에 구현
    final startIndex = state.messages.indexWhere((msg) => msg.id == state.shareRangeStartMessageId);
    final endIndex = state.shareRangeEndMessageId != null
        ? state.messages.indexWhere((msg) => msg.id == state.shareRangeEndMessageId)
        : -1;
    final currentMessageIndex = state.messages.indexWhere((msg) => msg.id == messageId);
    if (currentMessageIndex == -1) return true;
    if (startIndex > -1 && endIndex == -1) {
      if (startIndex == currentMessageIndex) {
        return false;
      }
    } else {
      if (currentMessageIndex >= startIndex && currentMessageIndex <= endIndex) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool showProfile = !state.isInShareCaptureMode ? true : !state.maskProfile;
    final bool showSenderName = !state.isInShareCaptureMode ? true : !state.maskBotName;

    print("showProfile : ${showProfile}");
    print("showSenderName : ${showSenderName}");

    // 기존 ListView.builder의 Column 코드
    return Column(
      children: [
        // 타임스탬프는 캡처 모드에서도 필요할 수 있으므로 그대로 둡니다.
        if (!forCapture && shouldShowTimestamp(message, messageIndex > 0 ? state.messages[messageIndex - 1] : null))
          Stack(children: [
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                formatTimestamp(message.createdAt),
                style: TextStyles.smallerTextRegular.copyWith(color: ColorStyles.gray3),
              ),
            ),
            if (state.isInShareCaptureMode)
              Positioned.fill(
                child: InkWell(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              )
          ]),
        Stack(children: [
          ChatBubble(
            message: message.text,
            isUser: message.senderId == state.currentUserId,
            showProfile: showProfile,
            showSenderName: showSenderName,
            senderName: message.senderId == state.currentUserId ? '나' : AppConstants.aiSenderId,
            profileImageUrl: message.senderId == state.currentUserId ? null : AppConstants.aiProfileImagePath,
            // 캡처 모드에서는 선택 상태가 필요 없으므로 false로 고정
            isSelectedForShare: false,
            // 캡처 모드에서는 onTap도 필요 없으므로 빈 함수 전달
            onTap: () {},
            chatMessage: message,
            // ChatBubble에도 forCapture 파라미터가 있다면 전달합니다.
            forCapture: forCapture,
          ),
          // 캡처 모드에서는 오버레이가 필요 없으므로 조건부로 렌더링
          if (!forCapture && isOverlay(message.id, state))
            Positioned.fill(
              child: InkWell(
                onTap: () {
                  onAction?.call(ChatAction.selectMessageForShare(message.id));
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
        ]),
      ],
    );
  }
}