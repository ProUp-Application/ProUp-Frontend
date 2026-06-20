import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_logo.dart';
import '../../../../core/widgets/proup_widgets.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Barra superior: marca + campana
            Row(
              children: [
                const ProupLogo(size: 30),
                const SizedBox(width: 8),
                Text('ProUp',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No tienes notificaciones nuevas')),
                  ),
                  icon: const Icon(Icons.notifications_none, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Saludo
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineMedium,
                children: [
                  const TextSpan(text: 'Hola, '),
                  TextSpan(
                    text: name.isNotEmpty ? name : 'profesional',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const TextSpan(text: '!'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Tu mentor IA está listo para la sesión de hoy.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Hero: escaneo de imagen
            HeroCard(
              tag: 'Recomendado',
              title: 'Escaneo de Imagen',
              subtitle:
                  'Analiza tu lenguaje corporal y vestimenta profesional con nuestra IA avanzada antes de tu gran entrevista.',
              actionLabel: 'Empezar Análisis',
              onAction: () => widget.onSelectTab(1),
            ),
            const SizedBox(height: 16),

            // Cards de acción
            _ActionCard(
              icon: Icons.video_camera_front_outlined,
              color: AppColors.primary,
              title: 'Simulador de Entrevista',
              subtitle: 'Practica con nuestra IA personalizada para tu sector.',
              onTap: () => context.push(AppRoutes.interview),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.auto_awesome,
              color: AppColors.tertiaryContainer,
              title: 'Asesor IA',
              subtitle: 'Resuelve tus dudas de empleabilidad al instante.',
              onTap: () => widget.onSelectTab(2),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.insights,
              color: AppColors.scoreMid,
              title: 'Mi Progreso',
              subtitle: 'Revisa tu evolución y tu historial de análisis.',
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
    return AmbientCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
