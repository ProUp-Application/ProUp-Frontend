import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento local de los tokens de sesión (JWT).
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  String? get accessToken => _prefs.getString(_kAccess);
  String? get refreshToken => _prefs.getString(_kRefresh);
  bool get hasSession => (accessToken ?? '').isNotEmpty;

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _prefs.setString(_kAccess, access);
    if (refresh != null) await _prefs.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
  }
}
