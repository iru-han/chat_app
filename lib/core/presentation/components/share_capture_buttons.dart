import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/presentation/components/chat_capture_content.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';
import 'dart:math';

class ShareCaptureButtons extends StatelessWidget {
  final ChatState state;
  final Function(ChatAction) onAction;
  final Future<void> Function(BuildContext, Widget) onConfirmAndCapture;
  final List<ChatMessage> messages;

  const ShareCaptureButtons({
    super.key,
    required this.state,
    required this.onAction,
    required this.onConfirmAndCapture,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              onAction(const ChatAction.showCaptureOptionsDialog());
            },
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  const Image(
                    width: 18,
                    image: AssetImage('assets/image/icon_filter.png'),
                  ),
                  Container(width: 5),
                  Text('캡쳐옵션', style: TextStyles.normalTextRegular.copyWith(color: ColorStyles.gray1)),
                ]
                )
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (state.shareRangeStartMessageId != null) {
                final startIndex = messages.indexWhere((msg) => msg.id == state.shareRangeStartMessageId);
                final endIndex = state.shareRangeEndMessageId != null
                    ? messages.indexWhere((msg) => msg.id == state.shareRangeEndMessageId)
                    : -1;

                int effectiveStartIndex = min(startIndex, endIndex);
                int effectiveEndIndex = max(startIndex, endIndex);

                if (startIndex == -1) {
                  onAction(const ChatAction.exitShareCaptureMode());
                  return;
                }
                if (state.shareRangeEndMessageId == null || endIndex == -1) {
                  effectiveEndIndex = startIndex;
                }

                final List<ChatMessage> messagesToCapture = [];
                for (int i = 0; i < messages.length; i++) {
                  if (i >= effectiveStartIndex && i <= effectiveEndIndex) {
                    messagesToCapture.add(messages[i]);
                  }
                }

                final Widget captureWidget = ChatCaptureContent(
                  messagesToCapture: messagesToCapture,
                  maskProfile: state.maskProfile,
                  maskBotName: state.maskBotName,
                  maskBackground: state.maskBackground,
                  state: state,
                );

                await onConfirmAndCapture(context, captureWidget);
              } else {
                onAction(const ChatAction.exitShareCaptureMode());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorStyles.blue1,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: Row(children: [
              const Image(
                width: 15,
                image: AssetImage('assets/image/icon_share.png'),
              ),
              Container(width: 8),
              Text('공유', style: TextStyles.normalTextRegular.copyWith(color: ColorStyles.white))
            ]),
          ),
        ],
      ),
    );
  }
}