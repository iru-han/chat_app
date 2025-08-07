import '../model/user.dart'; // We'll create this model

abstract interface class UserRepository {
  Future<User?> getCurrentUser();
  Future<User?> getUserById(String userId);
// Add other user related methods like signup, login, etc.
}