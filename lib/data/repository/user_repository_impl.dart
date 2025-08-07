import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../domain/model/user.dart';
import '../../domain/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient _supabase;

  UserRepositoryImpl({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<User?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    print("real current user : ${user}");
    if (user != null) {
      return User(
        id: user.id,
        email: user.email,
        username: user.userMetadata?['username'],
        createdAt: DateTime.parse(user.createdAt),
      );
    }
    return null;
  }

  @override
  Future<User?> getUserById(String userId) async {
    // This assumes the public.users table exists and is populated
    // You might need RLS policies to allow reading other user profiles
    try {
      final response = await _supabase.from('users').select('*').eq('id', userId).single();
      print("getUserById response : ${response}");
      if (response != null) {
        return User.fromJson(response);
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
    }
    return null;
  }
}