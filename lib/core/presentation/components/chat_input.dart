import 'package:flutter/material.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';

class ChatInput extends StatelessWidget {
  final ChatState state;
  final Function(ChatAction) onAction;
  final TextEditingController messageInputController;

  const ChatInput({
    super.key,
    required this.state,
    required this.onAction,
    required this.messageInputController,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey plusButtonKey = GlobalKey();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorStyles.gray4,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            key: plusButtonKey,
            icon: Image(
              width: 24,
              image: AssetImage(state.showPopupMenu ? 'assets/image/icon_cancel_circle.png' : 'assets/image/icon_more_circle.png'),
            ),
            onPressed: () {
              if (state.showPopupMenu) {
                onAction(const ChatAction.hidePopupMenu());
              } else {
                onAction(const ChatAction.showPopupMenu());
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: messageInputController,
              decoration: InputDecoration(
                hintText: state.isListening ? '듣고 있습니다...' : 'OBOA에게 메시지 보내기',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
              onSubmitted: (text) {
                onAction(ChatAction.sendChatMessageWithAttachments(
                  text,
                  state.selectedAttachments,
                ));
              },
            ),
          ),
          if (state.isListening)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: () => onAction(const ChatAction.stopListening()),
            )
          else
            IconButton(
              icon: const Image(
                width: 20,
                image: AssetImage('assets/image/icon_voice.png'),
              ),
              onPressed: () => onAction(const ChatAction.startListening()),
            ),
        ],
      ),
    );
  }
}