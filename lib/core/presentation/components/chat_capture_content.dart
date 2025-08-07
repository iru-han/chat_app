// lib/presentation/chat/screen/chat_capture_content.dart

import 'package:flutter/material.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_message_item.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';

class ChatCaptureContent extends StatelessWidget {
  final List<ChatMessage> messagesToCapture;
  final bool maskProfile;
  final bool maskBotName;
  final bool maskBackground;
  final ChatState state;
  final Widget? chatHeader;

  const ChatCaptureContent({
    super.key,
    required this.messagesToCapture,
    required this.maskProfile,
    required this.maskBotName,
    required this.maskBackground,
    required this.state,
    this.chatHeader,
  });

  @override
  Widget build(BuildContext context) {
    print("maskProfile :: ${maskProfile}");
    final Decoration? decoration = maskBackground
        ? null
        : const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/image/bg_sample.png'),
        fit: BoxFit.cover,
      ),
    );

    return Material( // <- Scaffold 대신 Material 위젯 사용
      color: Colors.white, // 배경색 지정
      child: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: decoration,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chatHeader != null) chatHeader!,
                ...messagesToCapture.asMap().entries.map((entry) {
                  final messageIndex = entry.key;
                  final message = entry.value;

                  return ChatMessageItem(
                    message: message,
                    messageIndex: messageIndex,
                    state: state,
                    onAction: null,
                    forCapture: true,
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}