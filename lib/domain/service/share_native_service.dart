// lib/data/service/share_native_service.dart
abstract interface class ShareNativeService {
  Future<String> shareImageToFacebook(String contentUrl);
  Future<bool> shareImageToInstagram(String imagePath, String deepLinkUrl); // <- 딥링크 URL 추가
  Future<bool> shareImageToTwitter(String imagePath, String text, String deepLinkUrl); // <- 딥링크 URL 추가
}