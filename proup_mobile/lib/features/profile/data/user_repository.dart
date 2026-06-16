import '../../../core/network/api_client.dart';
import '../../auth/data/models/user_model.dart';

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  Future<ProfileModel?> getProfile() async {
    final res = await _api.get('/users/me/profile');
    final p = (res.data as Map<String, dynamic>)['profile'];
    return p is Map<String, dynamic> ? ProfileModel.fromJson(p) : null;
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final res = await _api.put('/users/me/profile', data: profile.toJson());
    return ProfileModel.fromJson((res.data as Map<String, dynamic>)['profile'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> exportData() async {
    final res = await _api.get('/users/me/export');
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    await _api.delete('/users/me');
  }
}
