import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _levels = {
    'STUDENT': 'Estudiante',
    'JUNIOR': 'Junior',
    'SEMI_SENIOR': 'Semi senior',
    'SENIOR': 'Senior',
  };

  final _location = TextEditingController();
  final _goals = TextEditingController();
  List<ProfessionOption> _professions = [];
  String? _profession;
  String? _level;
  UserModel? _user;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _location.dispose();
    _goals.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await getIt<AuthRepository>().me();
      final profile = await getIt<UserRepository>().getProfile();
      final professions = await getIt<UserRepository>().getProfessions();
      if (!mounted) return;
      setState(() {
        _user = user;
        _professions = professions;
        _profession = profile?.profession;
        _level = profile?.experienceLevel;
        _location.text = profile?.location ?? '';
        _goals.text = profile?.careerGoals ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Completitud del perfil: nombre/correo (base) + 4 campos editables.
  int get _completeness {
    var pct = 20;
    if ((_profession ?? '').isNotEmpty) pct += 25;
    if ((_level ?? '').isNotEmpty) pct += 20;
    if (_location.text.trim().isNotEmpty) pct += 15;
    if (_goals.text.trim().isNotEmpty) pct += 20;
    return pct;
  }

  String get _professionLabel {
    final match = _professions.where((p) => p.id == _profession);
    return match.isNotEmpty ? match.first.label : '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<UserRepository>().updateProfile(ProfileModel(
        profession: _profession,
        experienceLevel: _level,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        careerGoals: _goals.text.trim().isEmpty ? null : _goals.text.trim(),
      ));
      if (!mounted) return;
      setState(() {}); // refresca el anillo de completitud
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo guardar el perfil')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await getIt<UserRepository>().exportData();
      final analyses = (data['analysisRequests'] as List?)?.length ?? 0;
      final interviews = (data['interviews'] as List?)?.length ?? 0;
      final chats = (data['chatSessions'] as List?)?.length ?? 0;
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tus datos (Ley 29733)'),
          content: Text(
              'ProUp guarda sobre ti: $analyses análisis de imagen (solo puntajes, nunca fotos), $interviews entrevistas simuladas y $chats conversaciones con el asesor.\n\nTienes derecho a acceder, rectificar, cancelar y oponerte al tratamiento de tus datos en cualquier momento.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))
          ],
        ),
      );
    } catch (_) {}
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar mi cuenta'),
        content: const Text(
            'Se eliminarán permanentemente tu cuenta y todos tus datos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await getIt<UserRepository>().deleteAccount();
      await getIt<AuthRepository>().logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo eliminar la cuenta')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                // ---- Hero: avatar + identidad ----
                Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerLow,
                      border: Border.all(color: AppColors.surfaceContainer, width: 4),
                      boxShadow: AppColors.ambientShadow,
                    ),
                    child: Center(
                      child: Text(
                        (_user?.firstName.isNotEmpty ?? false)
                            ? _user!.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(child: Text(_user?.fullName ?? '', style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 2),
                Center(child: Text(_user?.email ?? '', style: Theme.of(context).textTheme.bodySmall)),
                if (_professionLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: StatusChip(
                      label: _professionLabel,
                      background: AppColors.surfaceContainer,
                      foreground: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // ---- Fortaleza del perfil (bento azul con anillo) ----
                _ProfileStrengthCard(percent: _completeness),
                const SizedBox(height: 24),

                // ---- Datos profesionales ----
                Text('Datos profesionales', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                AmbientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue:
                            _professions.any((p) => p.id == _profession) ? _profession : null,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Profesión'),
                        items: _professions
                            .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.label, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _profession = v),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _levels.containsKey(_level) ? _level : null,
                        decoration: const InputDecoration(labelText: 'Nivel de experiencia'),
                        items: _levels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _level = v),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _location,
                        decoration: const InputDecoration(labelText: 'Ubicación'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _goals,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Metas profesionales'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Privacidad y datos (ARCO) ----
                Text('Privacidad y datos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                AmbientCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_outlined, color: AppColors.primary),
                        title: const Text('Ver mis datos'),
                        subtitle: const Text('Qué guarda ProUp sobre ti (Ley 29733)',
                            style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
                        onTap: _exportData,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppColors.onSurfaceVariant),
                        title: const Text('Cerrar sesión'),
                        onTap: () => getIt<AuthRepository>().logout(),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: AppColors.error),
                        title: const Text('Eliminar mi cuenta',
                            style: TextStyle(color: AppColors.error)),
                        subtitle: const Text('Borra todos tus datos de forma permanente',
                            style: TextStyle(fontSize: 12)),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Tarjeta azul de fortaleza del perfil con anillo de completitud (mockup 2.10).
class _ProfileStrengthCard extends StatelessWidget {
  const _ProfileStrengthCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Impulsa tu carrera al siguiente nivel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text(
                  percent >= 100
                      ? 'Tu perfil está completo: las recomendaciones y entrevistas ya se adaptan a ti.'
                      : 'Completa tu perfil para que el análisis, las entrevistas y el asesor se adapten mejor a tu carrera.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4EDEA3)),
                  ),
                ),
                Text('$percent%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
