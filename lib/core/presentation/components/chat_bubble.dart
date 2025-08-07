
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/domain/model/chat_message.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String message; // 기존 텍스트 메시지
  final bool isUser;
  final bool showProfile;
  final bool showSenderName;
  final String senderName;
  final String? profileImageUrl;
  final bool isSelectedForShare;
  final VoidCallback? onTap;
  final ChatMessage chatMessage;
  final bool forCapture;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.showProfile,
    required this.showSenderName,
    required this.senderName,
    this.profileImageUrl,
    this.isSelectedForShare = false,
    this.onTap,
    required this.chatMessage,
    this.forCapture = false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                child: showProfile ? CircleAvatar(
                  backgroundImage: profileImageUrl != null
                      ? AssetImage(profileImageUrl!)
                      : const AssetImage(AppConstants.aiProfileImagePath), // Default profile
                  radius: 20,
                ) : Container(),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        showSenderName ? senderName : '',
                        style: TextStyles.smallTextBold.copyWith(color: ColorStyles.black2),
                      ),
                    ),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                        margin: forCapture ? EdgeInsets.zero : EdgeInsets.only(
                          left: isUser ? 50.0 : 0.0,
                          right: isUser ? 0.0 : 50.0,
                        ),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUser
                              ? ColorStyles.primary
                              : ColorStyles.gray5,
                          borderRadius: BorderRadius.only(
                            topLeft: isUser ? const Radius.circular(20.0) : Radius.zero,
                            topRight: isUser ? Radius.zero : const Radius.circular(20.0),
                            bottomLeft: const Radius.circular(20.0),
                            bottomRight: const Radius.circular(20.0),
                          ),
                        ),
                        child: _buildMessageContent(context)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



// 메시지 타입에 따라 다른 내용 렌더링
  Widget _buildMessageContent(BuildContext context) {
    if (chatMessage.type == 'image' && chatMessage.imageUrl != null) {
      // 이미지 메시지
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: 150,
              width: 150,
              child: Image.network(
                chatMessage.imageUrl!,
                width: 200, // 이미지 너비 조절
                height: 200, // 이미지 높이 조절
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Text('이미지 로드 실패'), // 이미지 로드 실패 시
              )
          ),
          if (chatMessage.text.isNotEmpty) // 이미지가 텍스트 설명도 있다면 표시
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                chatMessage.text,
                style: TextStyles.smallTextRegular.copyWith(
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      );
    } else if (chatMessage.type == 'file' && chatMessage.fileUrl != null) {
      // 파일 메시지
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: isUser ? Colors.white : Colors.black),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              chatMessage.fileName ?? '파일', // 파일 이름 표시
              style: TextStyles.smallTextRegular.copyWith(
                color: isUser ? Colors.white : Colors.black,
                decoration: TextDecoration.underline, // 링크처럼 보이게
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // 일반 텍스트 메시지
      return Text(
        message, // chatMessage.text 사용 가능
        style: TextStyles.smallTextRegular.copyWith(
          color: isUser ? ColorStyles.white : ColorStyles.gray1,
        ),
      );
    }
  }
}