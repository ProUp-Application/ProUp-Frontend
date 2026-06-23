import '../../../core/auth/auth_notifier.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'models/user_model.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokenStorage, this._authNotifier);

  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final AuthNotifier _authNotifier;

  Future<UserModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? profession,
  }) async {
    final res = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      if (profession != null) 'profession': profession,
      'acceptedTerms': true,
    });
    final auth = AuthResult.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth.user;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final res = await _api.post('/auth/login', data: {'email': email, 'password': password});
    final auth = AuthResult.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth.user;
  }

  Future<UserModel> me() async {
    final res = await _api.get('/auth/me');
    return UserModel.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _authNotifier.notifyAuthChanged();
  }

  Future<void> _persist(AuthResult auth) async {
    await _tokenStorage.saveTokens(access: auth.accessToken, refresh: auth.refreshToken);
    _authNotifier.notifyAuthChanged();
  }
}
