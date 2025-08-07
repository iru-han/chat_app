// lib/presentation/chat/screen/components/chat_popup_menu.dart

import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/attachment_options_dialog.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';

class ChatPopupMenu extends StatelessWidget {
  final Function(ChatAction) onAction;

  const ChatPopupMenu({
    super.key,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    const double inputBarHeight = 10.0;

    return Positioned(
      bottom: keyboardHeight + bottomPadding + inputBarHeight - 16,
      left: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttachmentOptionsDialog(
            onTapFile: () {
              onAction(const ChatAction.pickFile());
              onAction(const ChatAction.hidePopupMenu());
            },
            onTapImage: () {
              onAction(const ChatAction.pickImage());
              onAction(const ChatAction.hidePopupMenu());
            },
            onTapShare: () {
              onAction(const ChatAction.enterShareCaptureMode());
              onAction(const ChatAction.hidePopupMenu());
            },
          ),
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: Image.asset(
              'assets/image/icon_bubble_link.png',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}