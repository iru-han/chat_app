import 'package:flutter/material.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

class AttachmentOptionsDialog extends StatelessWidget {
  final VoidCallback onTapFile;
  final VoidCallback onTapImage;
  final VoidCallback onTapShare;

  const AttachmentOptionsDialog({
    super.key,
    required this.onTapFile,
    required this.onTapImage,
    required this.onTapShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorStyles.gray1,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionButton(
              imagePath: 'assets/image/icon_file.png',
              label: '파일첨부',
              onTap: onTapFile,
            ),
            Container(height: 15, width: 1, color: ColorStyles.gray6),
            _buildOptionButton(
              imagePath: 'assets/image/icon_gallery.png',
              label: '이미지',
              onTap: onTapImage,
            ),
            Container(height: 15, width: 1, color: ColorStyles.gray6),
            _buildOptionButton(
              imagePath: 'assets/image/icon_share.png',
              label: '공유하기',
              onTap: onTapShare,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Image.asset(imagePath, width: 25, height: 25),
            const SizedBox(width: 8),
            Text(label, style: TextStyles.normalTextRegular.copyWith(color: ColorStyles.white)),
          ],
        ),
      ),
    );
  }
}