import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.mic_rounded,
                size: 80,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 32),
              const Text(
                'Your voice,\nyour story.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Record a voice note each day. Votio turns it into insights and a beautiful visual clip.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Get started',
                onPressed: () => context.go(RouteNames.login),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(RouteNames.login),
                child: Text(
                  'I already have an account',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
