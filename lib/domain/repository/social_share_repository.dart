abstract interface class SocialShareRepository {
  Future<void> shareToFacebook(String text, {String? hashtag, String? imageUrl});
  Future<void> shareToInstagram(String text, {String? imageUrl});
  Future<void> shareToKakaoTalk(String text);
  Future<void> copyLink(String link);
}