import 'package:flutter/material.dart';
import 'package:oboa_chat_app/ui/color_styles.dart';
import 'package:oboa_chat_app/ui/text_styles.dart';

class CaptureOptionsDialog extends StatelessWidget {
  final bool maskProfile;
  final bool maskBotName;
  final bool maskBackground;
  final ValueChanged<bool> onToggleProfile;
  final ValueChanged<bool> onToggleBotName;
  final ValueChanged<bool> onToggleBackground;
  final VoidCallback onConfirm;

  const CaptureOptionsDialog({
    super.key,
    required this.maskProfile,
    required this.maskBotName,
    required this.maskBackground,
    required this.onToggleProfile,
    required this.onToggleBotName,
    required this.onToggleBackground,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '캡쳐 옵션',
              style: TextStyles.largeTextBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _buildCheckboxRow('프로필 가리기', maskProfile, onToggleProfile),
            _buildCheckboxRow('봇 이름 가리기', maskBotName, onToggleBotName),
            _buildCheckboxRow('배경 가리기', maskBackground, onToggleBackground),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorStyles.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '확인',
                  style: TextStyles.mediumTextBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCheckboxRow(String title, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () {
        // 탭할 때마다 현재 값을 반전시킵니다.
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 'value'가 true일 때만 체크 아이콘을 표시합니다.
            Image(
              image: AssetImage(value ? 'assets/image/icon_check.png' : 'assets/image/icon_check_disable.png'), // 체크 아이콘 이미지 경로
              width: 12,
              height: 12,
            ),
            const SizedBox(width: 8.0), // 아이콘과 텍스트 사이 간격
            Text(title, style: TextStyles.smallTextBold.copyWith(color: ColorStyles.gray1)),
          ],
        ),
      ),
    );
  }
}