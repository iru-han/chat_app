import 'package:flutter/material.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

class ShareDialog extends StatelessWidget {
  final String link;
  final void Function(String link) onTapCopyLink;
  final VoidCallback onTapShareToInstagram;
  final VoidCallback onTapShareToX;
  final VoidCallback onTapShareToKakaoTalk;
  final VoidCallback onTapShareToFacebook;

  const ShareDialog({
    super.key,
    required this.link,
    required this.onTapCopyLink,
    required this.onTapShareToInstagram,
    required this.onTapShareToX,
    required this.onTapShareToKakaoTalk,
    required this.onTapShareToFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(
                '공유하기',
                style: TextStyles.mediumTextBold.copyWith(color: ColorStyles.gray1),
                textAlign: TextAlign.center,
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorStyles.gray7, // Or another accent color
                  borderRadius: BorderRadius.circular(100),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialShareButton('인스타그램', 'assets/image/icon_instagram.png', onTapShareToInstagram),
                _buildSocialShareButton('페이스북', 'assets/image/icon_facebook.png', onTapShareToFacebook),
                _buildSocialShareButton('카카오톡', 'assets/image/icon_kakaotalk.png', onTapShareToKakaoTalk),
                _buildSocialShareButton('X', 'assets/image/icon_twitter.png', onTapShareToX),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(
                  'URL 복사',
                  style: TextStyles.mediumTextBold.copyWith(color: ColorStyles.gray1),
                  textAlign: TextAlign.center,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    image: const DecorationImage(
                      image: AssetImage('assets/image/share_bubble.png'),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  margin: const EdgeInsets.only(left: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text.rich(
                    TextSpan(
                      text: '내 챗봇 공유하고 ',
                      style: TextStyles.smallerTextRegular.copyWith(color: Colors.white),
                      children: <TextSpan>[
                        TextSpan(
                          text: '150P',
                          style: TextStyles.smallerTextBold.copyWith(color: Colors.white),
                        ),
                        TextSpan(
                          text: ' 받기',
                          style: TextStyles.smallerTextRegular.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 15.0),
              decoration: BoxDecoration(
                color: ColorStyles.gray7,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: TextStyles.smallTextRegular.copyWith(color: ColorStyles.gray2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onTapCopyLink(link),
                    child: const Icon(Icons.copy, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 헬퍼 함수를 Image.asset 기반으로 수정
  Widget _buildSocialShareButton(String name, String imagePath, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: ColorStyles.gray7,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Image.asset(
                imagePath
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(name,
            textAlign: TextAlign.center,
            style: TextStyles.smallerTextRegular.copyWith(color: ColorStyles.gray1)
        )
        ),
      ],
    );
  }
}