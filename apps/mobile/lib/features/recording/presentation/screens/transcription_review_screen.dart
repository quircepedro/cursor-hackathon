import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../goals/application/providers/goals_provider.dart';
import '../../application/providers/recording_provider.dart';

class TranscriptionReviewScreen extends ConsumerStatefulWidget {
  const TranscriptionReviewScreen({
    super.key,
    required this.transcript,
  });

  final String transcript;

  @override
  ConsumerState<TranscriptionReviewScreen> createState() =>
      _TranscriptionReviewScreenState();
}

class _TranscriptionReviewScreenState
    extends ConsumerState<TranscriptionReviewScreen> {
  bool _isAnalysing = false;
  String? _error;

  Future<void> _analyse() async {
    if (_isAnalysing) return;
    setState(() {
      _isAnalysing = true;
      _error = null;
    });

    try {
      final repo = ref.read(recordingRepositoryProvider);
      final goals = ref.read(goalsProvider).goals;
      final insight = await repo.analyseJournal(
        widget.transcript,
        goals: goals,
      );
      if (!mounted) return;
      ref.read(recordingProvider.notifier).setAnalysedInsight(
            insight,
            transcript: widget.transcript,
          );
      context.pushReplacement(RouteNames.result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo analizar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript = widget.transcript.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your entry',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => context.go(RouteNames.home),
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Transcript header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRANSCRIPTION',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasTranscript
                          ? 'Review what was captured from your recording.'
                          : 'No speech detected in this recording.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Transcript body ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: hasTranscript
                      ? Text(
                          widget.transcript,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.7,
                            fontWeight: FontWeight.w300,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_off_outlined,
                                color: Colors.grey[700], size: 36),
                            const SizedBox(height: 12),
                            Text(
                              'No speech detected',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Analyse button ──
              if (hasTranscript)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: _isAnalysing ? null : _analyse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isAnalysing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6366F1)),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Ver insights y métricas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

              // ── Error ──
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}
