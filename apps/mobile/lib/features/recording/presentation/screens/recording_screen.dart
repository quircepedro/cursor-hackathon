import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record'), centerTitle: true),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // TODO: waveform widget
            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Waveform placeholder')),
            ),
            const SizedBox(height: 48),
            const Text('00:00', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            const Text('Tap the button to start recording'),
            const Spacer(),
            // Record button
            GestureDetector(
              onTap: () => context.pushReplacement(RouteNames.processing),
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
