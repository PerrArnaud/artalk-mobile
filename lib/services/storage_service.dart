import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';
  static const String _userAvatarKey = 'user_avatar';

  // Token operations
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data operations
  Future<void> saveUserData({
    required int id,
    required String email,
    required String name,
    required String role,
    String? avatar,
  }) async {
    await _storage.write(key: _userIdKey, value: id.toString());
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userRoleKey, value: role);
    await _storage.write(key: _userAvatarKey, value: avatar);
  }

  Future<void> saveAvatar(String? avatar) async {
    await _storage.write(key: _userAvatarKey, value: avatar);
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'id': await _storage.read(key: _userIdKey),
      'email': await _storage.read(key: _userEmailKey),
      'name': await _storage.read(key: _userNameKey),
      'role': await _storage.read(key: _userRoleKey),
      'avatar': await _storage.read(key: _userAvatarKey),
    };
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
