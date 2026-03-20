import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your insight')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clip placeholder
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Icon(Icons.play_circle_fill, size: 64)),
              ),
              const SizedBox(height: 24),
              Text('Today\'s emotion', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text('Hopeful', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                'You spoke about progress at work and feeling excited about an upcoming trip.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
