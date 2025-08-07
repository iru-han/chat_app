// lib/data/service/share_native_service_impl.dart
import 'package:flutter/services.dart';
import '../../domain/service/share_native_service.dart';

class ShareNativeServiceImpl implements ShareNativeService {
  static const MethodChannel _channel = MethodChannel('com.oboa.chat/social_share');

  /// 안드로이드와 iOS 네이티브에서 ShareLinkContent를 호출하는 메소드입니다.
  @override
  Future<String> shareImageToFacebook(String contentUrl) async {
    try {
      final String result = await _channel.invokeMethod(
        'shareLinkContent',
        {'contentUrl': contentUrl},
      );
      return result;
    } on PlatformException catch (e) {
      return "Failed to share: '${e.message}'.";
    }
  }

  @override
  Future<bool> shareImageToInstagram(String imagePath, String deepLinkUrl) async { // <- 딥링크 URL 추가
    try {
      final bool result = await _channel.invokeMethod('shareImageToInstagram', {
        'imagePath': imagePath,
        'deepLinkUrl': deepLinkUrl,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to share image to Instagram: '${e.message}'.");
      return false;
    }
  }

  @override
  Future<bool> shareImageToTwitter(String imagePath, String text, String deepLinkUrl) async { // <- 딥링크 URL 추가
    try {
      final bool result = await _channel.invokeMethod('shareImageToTwitter', {
        'imagePath': imagePath,
        'text': text,
        'deepLinkUrl': deepLinkUrl,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to share image to Twitter: '${e.message}'.");
      return false;
    }
  }
}