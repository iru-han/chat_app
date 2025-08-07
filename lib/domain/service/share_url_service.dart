// lib/domain/service/share_url_service.dart

abstract class ShareUrlService {
  String generateTwitterUrl({
    required String baseFunctionUrl,
    required String roomId,
    String? imageUrl,
    String? title,
    String? description,
  });

  String generateFacebookUrl({
    required String baseFunctionUrl,
    required String roomId,
    String? imageUrl,
    String? title,
    String? description,
  });

// 카카오톡 등 다른 SNS를 위한 메서드도 여기에 추가 가능
}