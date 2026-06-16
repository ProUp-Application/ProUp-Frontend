import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _sectors = ['Tecnología', 'Finanzas', 'Banca', 'Educación', 'Salud', 'Marketing', 'Creativo'];
  static const _levels = {
    'STUDENT': 'Estudiante',
    'JUNIOR': 'Junior',
    'SEMI_SENIOR': 'Semi senior',
    'SENIOR': 'Senior',
  };

  final _location = TextEditingController();
  final _goals = TextEditingController();
  String? _sector;
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
      if (!mounted) return;
      setState(() {
        _user = user;
        _sector = profile?.targetSector;
        _level = profile?.experienceLevel;
        _location.text = profile?.location ?? '';
        _goals.text = profile?.careerGoals ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<UserRepository>().updateProfile(ProfileModel(
        targetSector: _sector,
        experienceLevel: _level,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        careerGoals: _goals.text.trim().isEmpty ? null : _goals.text.trim(),
      ));
      if (!mounted) return;
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
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tus datos (Ley 29733)'),
          content: Text(
              'Tienes $analyses análisis y $interviews entrevistas registradas.\n\nTienes derecho a acceder, rectificar, cancelar y oponerte al tratamiento de tus datos personales.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
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
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFD23B3B))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await getIt<UserRepository>().deleteAccount();
      await getIt<AuthRepository>().logout(); // limpia sesión -> router redirige a login
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
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      (_user?.firstName.isNotEmpty ?? false) ? _user!.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(_user?.fullName ?? '', style: Theme.of(context).textTheme.titleLarge)),
                Center(child: Text(_user?.email ?? '', style: Theme.of(context).textTheme.bodySmall)),
                const SizedBox(height: 24),
                Text('Datos profesionales', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sectors.contains(_sector) ? _sector : null,
                  decoration: const InputDecoration(labelText: 'Sector objetivo'),
                  items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _sector = v),
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
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _goals,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Metas profesionales'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar cambios'),
                ),
                const Divider(height: 40),
                Text('Privacidad y datos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Exportar mis datos'),
                  onTap: _exportData,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  onTap: () => getIt<AuthRepository>().logout(),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFD23B3B)),
                  title: const Text('Eliminar mi cuenta', style: TextStyle(color: Color(0xFFD23B3B))),
                  onTap: _deleteAccount,
                ),
              ],
            ),
    );
  }
}
