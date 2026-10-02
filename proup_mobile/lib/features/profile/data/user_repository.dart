import '../../../core/network/api_client.dart';
import '../../auth/data/models/user_model.dart';

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  /// Catálogo de respaldo (mismos IDs que `ProUp-Backend/src/shared/professions.ts`).
  /// Se usa si el servidor no responde, para que el selector nunca quede vacío.
  static const fallbackProfessions = <ProfessionOption>[
    ProfessionOption(id: 'administracion', label: 'Administración y Negocios'),
    ProfessionOption(id: 'contabilidad', label: 'Contabilidad y Finanzas'),
    ProfessionOption(id: 'economia', label: 'Economía'),
    ProfessionOption(id: 'derecho', label: 'Derecho'),
    ProfessionOption(id: 'sistemas', label: 'Ingeniería de Sistemas / Software'),
    ProfessionOption(id: 'industrial', label: 'Ingeniería Industrial'),
    ProfessionOption(id: 'civil', label: 'Ingeniería Civil'),
    ProfessionOption(id: 'marketing', label: 'Marketing y Publicidad'),
    ProfessionOption(id: 'diseno', label: 'Diseño Gráfico / UX'),
    ProfessionOption(id: 'comunicaciones', label: 'Comunicaciones / Periodismo'),
    ProfessionOption(id: 'arquitectura', label: 'Arquitectura'),
    ProfessionOption(id: 'psicologia', label: 'Psicología'),
    ProfessionOption(id: 'salud', label: 'Salud / Enfermería'),
    ProfessionOption(id: 'educacion', label: 'Educación'),
    ProfessionOption(id: 'rrhh', label: 'Recursos Humanos'),
    ProfessionOption(id: 'ventas', label: 'Ventas / Comercial'),
    ProfessionOption(id: 'turismo', label: 'Turismo / Hotelería'),
    ProfessionOption(id: 'otra', label: 'Otra profesión'),
  ];

  Future<List<ProfessionOption>> getProfessions() async {
    try {
      final res = await _api.get('/professions');
      final items = (res.data as Map<String, dynamic>)['professions'] as List<dynamic>? ?? [];
      final list = items.map((e) => ProfessionOption.fromJson(e as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : fallbackProfessions;
    } catch (_) {
      return fallbackProfessions;
    }
  }

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
