import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/injector.dart';
import '../../core/router/app_routes.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/proup_logo.dart';
import '../auth/data/auth_repository.dart';

/// Pantalla de arranque (mockup 2.1): valida la sesión y decide a dónde ir.
/// - Primera vez → onboarding.
/// - Sin sesión → login.
/// - Con sesión → valida/renueva el token y entra a home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const onboardingSeenKey = 'onboarding_seen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final storage = getIt<TokenStorage>();
    final prefs = getIt<SharedPreferences>();

    // Pequeña pausa de marca (y deja pintar el primer frame)
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (!storage.hasSession) {
      final seen = prefs.getBool(SplashScreen.onboardingSeenKey) ?? false;
      context.go(seen ? AppRoutes.login : AppRoutes.onboarding);
      return;
    }

    // Hay sesión guardada: se valida contra el backend.
    // Si el access token expiró, el ApiClient lo renueva solo.
    try {
      await getIt<AuthRepository>().me();
      if (mounted) context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      if (getIt<TokenStorage>().hasSession) {
        // Falla de red transitoria: no bloquear al usuario
        context.go(AppRoutes.home);
      } else {
        // La sesión fue invalidada (refresh expirado)
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ProupLogo(size: 96),
                  const SizedBox(height: 28),
                  Text('ProUp',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text('Tu asesor de imagen profesional con IA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('CARGANDO TU CARRERA',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text('© 2026 ProUp · Lima, Perú',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
            ),
          ],
        ),
      ),
    );
  }
}
