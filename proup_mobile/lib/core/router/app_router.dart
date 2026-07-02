import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../di/injector.dart';
import '../../features/analysis/data/models/analysis_models.dart';
import '../../features/analysis/presentation/screens/results_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/home_shell.dart';
import '../../features/interview/data/models/interview_models.dart';
import '../../features/interview/presentation/screens/interview_feedback_screen.dart';
import '../../features/interview/presentation/screens/interview_selection_screen.dart';
import '../../features/interview/presentation/screens/interview_session_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/startup/splash_screen.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = _build();

  static GoRouter _build() {
    final auth = getIt<AuthNotifier>();
    const publicRoutes = {
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.register,
    };

    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        // El splash decide por sí mismo (valida sesión y navega)
        if (loc == AppRoutes.splash) return null;

        final authed = auth.isAuthenticated;
        final isPublic = publicRoutes.contains(loc);

        if (!authed && !isPublic) return AppRoutes.login;
        if (authed && isPublic) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
        GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeShell()),
        GoRoute(
          path: AppRoutes.analysisResult,
          builder: (_, state) => ResultsScreen(analysis: state.extra as AnalysisModel),
        ),
        GoRoute(path: AppRoutes.interview, builder: (_, __) => const InterviewSelectionScreen()),
        GoRoute(
          path: AppRoutes.interviewSession,
          builder: (_, state) => InterviewSessionScreen(start: state.extra as InterviewStart),
        ),
        GoRoute(
          path: AppRoutes.interviewFeedback,
          builder: (_, state) =>
              InterviewFeedbackScreen(simulation: state.extra as InterviewSimulationModel),
        ),
      ],
    );
  }
}

