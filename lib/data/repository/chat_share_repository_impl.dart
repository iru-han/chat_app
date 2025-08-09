import 'package:oboa_chat_app/data/data_source/supabase_chat_share_data_source.dart';
import 'package:oboa_chat_app/domain/repository/chat_share_repository.dart';

class ChatShareRepositoryImpl implements ChatShareRepository {
  final SupabaseShareDataSource _dataSource;

  ChatShareRepositoryImpl({required SupabaseShareDataSource dataSource}) : _dataSource = dataSource;

  @override
  Future<String> insertShareImage({
    required String roomId,
    required String userId,
    required String imageUrl,
    String? title,
    String? description
  }) {
    return _dataSource.insertShareImage(roomId: roomId, userId: userId, imageUrl: imageUrl);
  }
}