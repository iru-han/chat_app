// lib/data/service/share_url_service_impl.dart
import 'dart:core';

import '../../domain/service/share_url_service.dart' show ShareUrlService;

class ShareUrlServiceImpl implements ShareUrlService {
  @override
  String generateTwitterUrl({
    required String baseFunctionUrl,
    required String roomId,
    String? imageUrl,
    String? title,
    String? description,
  }) {
    final Map<String, dynamic> queryParams = {
      'roomId': roomId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };
    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&');
    return '$baseFunctionUrl?$queryString';
  }

  @override
  String generateFacebookUrl({
    required String baseFunctionUrl,
    required String roomId,
    String? imageUrl,
    String? title,
    String? description,
  }) {
    final Map<String, dynamic> queryParams = {
      'roomId': roomId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };
    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&');
    return '$baseFunctionUrl?$queryString';
  }
}