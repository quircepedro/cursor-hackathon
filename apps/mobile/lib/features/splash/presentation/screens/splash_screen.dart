import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/application/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show splash for at least 1.5 seconds
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Wait for auth state to resolve (up to 5 seconds)
    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      // Auth hasn't resolved yet — wait for it
      await ref.read(authProvider.future).timeout(
            const Duration(seconds: 5),
            onTimeout: () => const AuthState(status: AuthStatus.unauthenticated),
          );
      if (!mounted) return;
    }

    final status = ref.read(authProvider).valueOrNull?.status;
    if (status == AuthStatus.authenticated) {
      context.go(RouteNames.home);
    } else if (status == AuthStatus.pendingVerification) {
      context.go(RouteNames.verifyEmail);
    } else {
      // Unauthenticated or unknown — go to onboarding/login
      context.go(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050505),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_rounded,
              size: 72,
              color: Color(0xFF6366F1),
            ),
            SizedBox(height: 16),
            Text(
              'Votio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
