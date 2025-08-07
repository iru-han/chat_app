import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/constants/app_constants.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

class ChatHeader extends StatefulWidget {
  final String imageUrl;
  final String text;
  final void Function() goBack;
  final void Function() onPressSetting;

  const ChatHeader(
    {
    super.key,
      required this.imageUrl,
      required this.text,
      required this.goBack,
      required this.onPressSetting,
  });

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1, color: ColorStyles.gray4),
            ),
          ),
        child: Row(children: [
          InkWell(
              onTap: widget.goBack,
              child: const Image(
                width: 12,
                image: AssetImage('assets/image/icon_back.png'),
              )
          ),
          Container(width: 15),
          CircleAvatar(
            radius: 15,
            backgroundImage: AssetImage(widget.imageUrl),
            backgroundColor: ColorStyles.gray1,
          ),
          Container(width: 15),
          Text(
            widget.text ?? AppConstants.aiSenderId,
            style: TextStyles.mediumTextBold,
          ),
          Spacer(),
          InkWell(
              onTap: widget.onPressSetting,
              child: const Image(
                width: 24,
                image: AssetImage('assets/image/icon_settings.png'),
              )
          ),
        ])
      );
  }
}
