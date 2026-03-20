import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Unlock Votio Pro', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'Unlimited recordings, advanced insights, and HD clips.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              // TODO: wire to SubscriptionsModule
              ElevatedButton(
                onPressed: () {},
                child: const Text('Start free trial'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Maybe later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
