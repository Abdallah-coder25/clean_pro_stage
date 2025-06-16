import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  final SharedPreferences _prefs;

  AuthService(this._prefs);
  // Mock users for demo
  final Map<String, ({User user, String password})> _mockUsers = {
    'admin': (
      user: User(
        id: 'admin1',
        username: 'admin',
        name: 'Admin User',
        role: UserRole.admin,
      ),
      password: 'admin123',
    ),
    'cleaner1': (
      user: User(
        id: 'cleaner1',
        username: 'cleaner1',
        name: 'John Doe',
        role: UserRole.cleaner,
      ),
      password: 'cleaner1',
    ),
    'cleaner2': (
      user: User(
        id: 'cleaner2',
        username: 'cleaner2',
        name: 'Jane Smith',
        role: UserRole.cleaner,
      ),
      password: 'cleaner2',
    ),
  };

  User? getCurrentUser() {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(
      Map<String, dynamic>.from(Map.from(_prefs.getString(_userKey) as Map)),
    );
  }

  Future<User?> login(String username, String password) async {
    if (_mockUsers.containsKey(username) &&
        _mockUsers[username]!.password == password) {
      final user = _mockUsers[username]!.user;
      await _prefs.setString(_userKey, user.toJson().toString());
      return user;
    }
    return null;
  }

  Future<void> logout() async {
    await _prefs.remove(_userKey);
  }

  List<User> getCleaners() {
    return _mockUsers.values
        .where((record) => record.user.role == UserRole.cleaner)
        .map((record) => record.user)
        .toList();
  }
}
