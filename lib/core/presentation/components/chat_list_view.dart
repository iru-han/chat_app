import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_message_item.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

class ChatListView extends StatelessWidget {
  final ScrollController chatListScrollController;
  final ChatState state;
  final void Function(ChatAction action) onAction;

  const ChatListView({
    super.key,
    required this.chatListScrollController,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // 배경 이미지 마스킹 여부에 따라 다른 decoration을 적용
    final Decoration? decoration = state.maskBackground
        ? null // 마스킹 시 배경 없음
        : const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/image/bg_sample.png'),
        fit: BoxFit.cover,
      ),
    );

    return Container(
      decoration: decoration,
      child: RepaintBoundary(
        child: ListView.builder(
          key: const PageStorageKey<String>('chatListView'),
          physics: state.isInShareCaptureMode
              ? const NeverScrollableScrollPhysics() // 캡처 모드일 때 스크롤 비활성화
              : const AlwaysScrollableScrollPhysics(), // 평상시 스크롤 허용
          controller: chatListScrollController,
          reverse: false,
          itemCount: state.messages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Stack(children: [
                _buildChatHeader(state),
                if (state.isInShareCaptureMode)
                  Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      )
                  )
              ]);
            }

            final messageIndex = index - 1;
            final message = state.messages[messageIndex];

            return ChatMessageItem(
              message: message,
              messageIndex: messageIndex,
              state: state,
              onAction: (action) {
                onAction(action);
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _buildChatHeader(ChatState state) {
  return Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 20),
      const CircleAvatar(
        radius: 40,
        backgroundImage: AssetImage(AppConstants.aiProfileImagePath),
        backgroundColor: ColorStyles.gray1,
      ),
      const SizedBox(height: 16),
      Text(
        '나의 새로운 AI 친구',
        style: TextStyles.largeTextBold.copyWith(color: Colors.black),
      ),
      const SizedBox(height: 20),
    ],
  ));
}