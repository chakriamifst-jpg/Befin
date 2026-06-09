import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken  = 'jwt_token';
  static const _keyUserId = 'user_id';
  static const _keyType   = 'user_type';

  static Future<void> saveSession({
    required String token,
    required String userId,
    required String userType,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken,  value: token),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyType,   value: userType),
    ]);
  }

  static Future<String?> getToken()    => _storage.read(key: _keyToken);
  static Future<String?> getUserType() => _storage.read(key: _keyType);

  static Future<int?> getUserId() async {
    final v = await _storage.read(key: _keyUserId);
    return v != null ? int.tryParse(v) : null;
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() => _storage.deleteAll();
}
