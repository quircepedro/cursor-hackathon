import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../application/providers/recording_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, this.extra});

  /// Either a recordingId (String from TranscriptionReviewScreen)
  /// or an audioPath (String from RecordingScreen direct flow).
  final String? extra;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickOff());
  }

  Future<void> _kickOff() async {
    if (_started || widget.extra == null) return;
    _started = true;

    final notifier = ref.read(recordingProvider.notifier);
    final currentState = ref.read(recordingProvider);

    // If we already have a recordingId in state (came from TranscriptionReviewScreen),
    // just continue with the analysis phase.
    if (currentState.recordingId != null) {
      await notifier.continueAnalysis(currentState.recordingId!);
    } else {
      // Direct flow: extra is an audioPath
      await notifier.stopAndProcess(widget.extra!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingProvider);

    if (!_navigated &&
        (state.status == RecordingStatus.complete ||
            state.status == RecordingStatus.error)) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(RouteNames.result);
      });
    }

    final isError = state.status == RecordingStatus.error;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: isError
                  ? [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 48),
                      const SizedBox(height: 24),
                      Text(
                        state.error ?? 'Something went wrong.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ]
                  : [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1)),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        state.statusLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will just take a moment',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
