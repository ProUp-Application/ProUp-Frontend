import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card blanca con sombra ambiental difusa (estilo "Career Card" del DESIGN.md).
class AmbientCard extends StatelessWidget {
  const AmbientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: card),
    );
  }
}

/// Pill de estado/categoría.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.onSurfaceVariant,
    this.uppercase = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        uppercase ? label.toUpperCase() : label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: uppercase ? 0.6 : 0,
          color: foreground,
        ),
      ),
    );
  }
}

/// Cuadro redondeado con un ícono (acentos de las cards de acción).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Encabezado de sección con título y acción opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Tarjeta "hero" azul con degradado (la del dashboard).
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.center_focus_strong,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 160, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                  label: tag,
                  background: Colors.white.withValues(alpha: 0.2),
                  foreground: Colors.white,
                  uppercase: true,
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white)),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 15, height: 1.45, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                  onPressed: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(actionLabel),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
