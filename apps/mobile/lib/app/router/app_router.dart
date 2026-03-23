import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/goals/application/providers/goals_provider.dart';
import '../../features/goals/presentation/screens/goals_onboarding_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/today_insights_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/paywall/presentation/screens/paywall_screen.dart';
import '../../features/recording/presentation/screens/processing_screen.dart';
import '../../features/recording/presentation/screens/recording_screen.dart';
import '../../features/recording/presentation/screens/result_screen.dart';
import '../../features/recording/presentation/screens/transcription_review_screen.dart';
import '../../features/settings/presentation/screens/charts_preview_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../shell/shell_scaffold.dart' show AnimatedTabShell, ShellScaffold;
import 'route_names.dart';

const _publicRoutes = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
  RouteNames.forgotPassword,
};

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);
  ref.watch(goalsProvider);

  ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
    final prevStatus = prev?.valueOrNull?.status;
    final nextStatus = next.valueOrNull?.status;
    if (prevStatus != AuthStatus.authenticated &&
        nextStatus == AuthStatus.authenticated) {
      ref.read(goalsProvider.notifier).loadGoals();
    }
  });

  final router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authStatus = ref.read(authProvider).valueOrNull?.status;
      final isPublic = _publicRoutes.contains(state.matchedLocation);
      final isVerifyEmail = state.matchedLocation == RouteNames.verifyEmail;

      if (authStatus == null || authStatus == AuthStatus.unknown) return null;

      if (authStatus == AuthStatus.unauthenticated) {
        return isPublic ? null : RouteNames.login;
      }

      if (authStatus == AuthStatus.pendingVerification) {
        return isVerifyEmail ? null : RouteNames.verifyEmail;
      }

      final goalsStatus = ref.read(goalsProvider).status;
      final isGoalsOnboarding =
          state.matchedLocation == RouteNames.goalsOnboarding;

      if (goalsStatus == GoalsStatus.noGoals) {
        return isGoalsOnboarding ? null : RouteNames.goalsOnboarding;
      }

      if (goalsStatus == GoalsStatus.loading) {
        // Don't trap authenticated users on public/auth screens while goals load.
        // Send them to home; when goals resolve the next redirect will handle it.
        if (isPublic || isVerifyEmail) return RouteNames.home;
        return null;
      }

      if (isPublic || isVerifyEmail || isGoalsOnboarding) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
      // ── Auth / onboarding (no shell) ────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ForgotPasswordScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: RouteNames.goalsOnboarding,
        name: 'goalsOnboarding',
        builder: (context, state) => const GoalsOnboardingScreen(),
      ),

      // ── Full-screen flows (no shell) ─────────────────────────────────────────
      GoRoute(
        path: RouteNames.recording,
        name: 'recording',
        pageBuilder: (context, state) {
          final extra = state.extra as (double, double)?;
          return CustomTransitionPage(
            child: RecordingScreen(
              initialMorphTime: extra?.$1 ?? 0.0,
              initialPulseTime: extra?.$2 ?? 0.0,
            ),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: RouteNames.transcriptionReview,
        name: 'transcriptionReview',
        builder: (context, state) => TranscriptionReviewScreen(
          transcript: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.processing,
        name: 'processing',
        builder: (context, state) =>
            ProcessingScreen(extra: state.extra as String?),
      ),
      GoRoute(
        path: RouteNames.result,
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: RouteNames.paywall,
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: RouteNames.goals,
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: RouteNames.chartsPreview,
        name: 'chartsPreview',
        builder: (context, state) => const ChartsPreviewScreen(),
      ),
      GoRoute(
        path: RouteNames.historyDetail,
        name: 'historyDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HistoryDetailScreen(entryId: id);
        },
      ),

      // ── Main tabs — persistent shell with fixed navbar + fade transitions ─────
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedTabShell(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.history,
                name: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.todayInsights,
                name: 'todayInsights',
                builder: (context, state) => const TodayInsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
  return router;
});
