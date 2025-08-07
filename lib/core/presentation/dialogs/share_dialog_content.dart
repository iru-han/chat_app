import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/presentation/dialogs/share_dialog.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_state.dart';

class ShareDialogContent extends StatelessWidget {
  final ChatState state;
  final Function(ChatAction) onAction;

  const ShareDialogContent({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ShareDialog(
      link: 'oboa_chat_app://chat?roomId=${state.currentChatRoom?.id ?? 'default_room'}',
      onTapCopyLink: (link) {
        onAction(ChatAction.copyShareLink(link));
        Navigator.pop(context); // 바텀시트 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크가 복사되었습니다!', textAlign: TextAlign.center),
          ),
        );
      },
      onTapShareToInstagram: () async {
        final String? capturedImagePath = state.tempImagePath;
        if (capturedImagePath != null) {
          onAction(ChatAction.shareCapturedImageToInstagram(capturedImagePath));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 캡처 실패')),
          );
        }
        Navigator.pop(context);
      },
      onTapShareToX: () async {
        final String? shareUrl = state.shareUrl;
        if (shareUrl != null) {
          onAction(ChatAction.shareToTwitter(state.shareUrl!));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 캡처 실패')),
          );
        }
        Navigator.pop(context);
      },
      onTapShareToKakaoTalk: () async {
        final String? capturedImagePath = state.tempImagePath;
        if (capturedImagePath != null) {
          onAction(ChatAction.shareCapturedImageToKakaoTalk(capturedImagePath));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 캡처 실패')),
          );
        }
        Navigator.pop(context);
      },
      onTapShareToFacebook: () async {
        final String? capturedImagePath = state.tempImagePath;
        if (capturedImagePath != null) {
          onAction(ChatAction.shareCapturedImageToFacebook(capturedImagePath));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 캡처 실패')),
          );
        }
        Navigator.pop(context);
      },
    );
  }
}