import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/paywall/presentation/screens/paywall_screen.dart';
import '../../features/recording/presentation/screens/processing_screen.dart';
import '../../features/recording/presentation/screens/recording_screen.dart';
import '../../features/recording/presentation/screens/result_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'route_names.dart';

const _publicRoutes = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
};

final routerProvider = Provider<GoRouter>((ref) {
  // Watching authProvider causes routerProvider to rebuild — and GoRouter to
  // re-evaluate redirect — whenever auth state changes.
  ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // ref.read is intentional: the outer ref.watch above is the reactive
      // trigger. Using ref.watch here would cause an infinite rebuild loop.
      final authStatus = ref.read(authProvider).valueOrNull?.status;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (authStatus == null || authStatus == AuthStatus.unknown) return null;
      if (authStatus == AuthStatus.unauthenticated && !isPublic) {
        return RouteNames.login;
      }
      if (authStatus == AuthStatus.authenticated && isPublic) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
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
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.recording,
        name: 'recording',
        builder: (context, state) => const RecordingScreen(),
      ),
      GoRoute(
        path: RouteNames.processing,
        name: 'processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: RouteNames.result,
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: RouteNames.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.historyDetail,
        name: 'historyDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HistoryDetailScreen(entryId: id);
        },
      ),
      GoRoute(
        path: RouteNames.paywall,
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
