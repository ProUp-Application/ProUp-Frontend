import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key, required this.onSelectTab});

  final void Function(int index) onSelectTab;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await getIt<AuthRepository>().me();
      if (mounted) setState(() => _user = user);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.firstName ?? '';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Hola${name.isNotEmpty ? ', $name' : ''} 👋',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Mejora tu imagen profesional y tu empleabilidad',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            _ActionCard(
              icon: Icons.center_focus_strong,
              color: AppTheme.primaryColor,
              title: 'Analizar mi imagen',
              subtitle: 'Escanea tu rostro o vestimenta y recibe un puntaje',
              onTap: () => widget.onSelectTab(1),
            ),
            _ActionCard(
              icon: Icons.record_voice_over,
              color: AppTheme.tertiaryColor,
              title: 'Simular una entrevista',
              subtitle: 'Practica con preguntas reales y recibe feedback',
              onTap: () => context.push(AppRoutes.interview),
            ),
            _ActionCard(
              icon: Icons.chat_bubble,
              color: const Color(0xFF7A5AF8),
              title: 'Hablar con el asesor IA',
              subtitle: 'Resuelve tus dudas de empleabilidad',
              onTap: () => widget.onSelectTab(2),
            ),
            _ActionCard(
              icon: Icons.insights,
              color: const Color(0xFFE0A100),
              title: 'Ver mi progreso',
              subtitle: 'Revisa tu evolución a lo largo del tiempo',
              onTap: () => widget.onSelectTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB0B4C2)),
            ],
          ),
        ),
      ),
    );
  }
}
