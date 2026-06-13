import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/image_analysis/presentation/screens/image_analysis_result_screen.dart';
import '../../features/image_analysis/presentation/screens/image_scan_screen.dart';
import '../../features/interview/presentation/screens/interview_feedback_screen.dart';
import '../../features/interview/presentation/screens/interview_selection_screen.dart';
import '../../features/interview/presentation/screens/interview_session_screen.dart';

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
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageAnalysis,
        builder: (context, state) => const ImageScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageAnalysisResult,
        builder: (context, state) => const ImageAnalysisResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.interview,
        builder: (context, state) => const InterviewSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.interviewSession,
        builder: (context, state) => const InterviewSessionScreen(),
      ),
      GoRoute(
        path: AppRoutes.interviewFeedback,
        builder: (context, state) => const InterviewFeedbackScreen(),
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