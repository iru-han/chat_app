import 'package:oboa_chat_app/domain/repository/social_share_repository.dart';

class ShareChatUseCase {
  final SocialShareRepository _socialShareRepository;

  ShareChatUseCase(this._socialShareRepository);

  Future<void> shareToFacebook(String text, {String? hashtag, String? imageUrl}) async {
    await _socialShareRepository.shareToFacebook(text, hashtag: hashtag, imageUrl: imageUrl);
  }

  Future<void> shareToInstagram(String text, {String? imageUrl}) async {
    await _socialShareRepository.shareToInstagram(text, imageUrl: imageUrl);
  }

  Future<void> shareToKakaoTalk(String text) async {
    await _socialShareRepository.shareToKakaoTalk(text);
  }

  Future<void> copyLink(String link) async {
    await _socialShareRepository.copyLink(link);
  }
}