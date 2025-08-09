abstract interface class ChatShareRepository {
  Future<String> insertShareImage({
    required String roomId,
    required String userId,
    required String imageUrl,
    String? title,
    String? description
  });
}