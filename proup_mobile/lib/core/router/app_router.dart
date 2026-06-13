import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';

import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _PlaceholderScreen(title: 'Splash'),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: AppRoutes.imageAnalysis,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Análisis de imagen'),
      ),
      GoRoute(
        path: AppRoutes.interview,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Simulador de entrevista'),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        builder: (context, state) => const _PlaceholderScreen(title: 'Chatbot'),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Progreso'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const _PlaceholderScreen(title: 'Perfil'),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}