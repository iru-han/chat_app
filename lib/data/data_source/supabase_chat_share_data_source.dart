import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseShareDataSource {
  final SupabaseClient _supabase;

  SupabaseShareDataSource(this._supabase);

  Future<String> insertShareImage({
    required String roomId,
    required String userId,
    required String imageUrl,
    String? title,
    String? description
  }) async {
    Map<String, dynamic> insertData = {
      'room_id': roomId,
      'user_id': userId,
      'image_url': imageUrl,
      'title': title ?? 'OBOA AI Chat',
      'description': description ?? 'AI 친구 OBOA와 대화해보세요!'
    };
    // .insert() 후 .select()를 호출하여 삽입된 레코드를 반환받음
    final List<Map<String, dynamic>> response = await _supabase
        .from('chat_shares')
        .insert(insertData)
        .select('id'); // id만 선택적으로 가져올 수도 있음

    if (response.isEmpty) {
      throw Exception('Failed to insert share image data.');
    }

    // 반환된 응답(List)에서 첫 번째 레코드의 id를 추출하여 반환
    final String shareId = response.first['id'] as String;
    return shareId;
  }
}