import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../goals/application/providers/goals_provider.dart';
import '../../../recording/application/providers/recording_provider.dart';
import '../../../recording/domain/repositories/recording_repository.dart';
import '../../../recording/presentation/widgets/journal_audio_player.dart';
import '../../../history/application/providers/history_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _morphController;
  late AnimationController _pulseController;
  late AnimationController _exitController;

  // Exit animations
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _contentSlide;
  late Animation<Offset> _navSlide;
  late Animation<double> _exitFade;

  Timer? _pollTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    final curve = CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic);

    _headerSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.5))
        .animate(curve);
    _contentSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.4))
        .animate(curve);
    _navSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.2))
        .animate(curve);
    _exitFade = Tween<double>(begin: 1, end: 0).animate(curve);

    _refreshToday();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true &&
        _exitController.value > 0) {
      _exitController.reverse();
    }
    _refreshToday();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshToday();
    }
  }

  void _refreshToday() {
    unawaited(ref.read(todayRecordingProvider.notifier).refresh());
  }

  void _startPollingIfNeeded(TodayRecordingResponse? today) {
    final shouldPoll = today != null && !today.isComplete;
    if (shouldPoll && !_isPolling) {
      _isPolling = true;
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        _refreshToday();
      });
    } else if (!shouldPoll && _isPolling) {
      _isPolling = false;
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _morphController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _onBlobTap() async {
    if (_exitController.isAnimating || _exitController.value == 1) return;

    final todayAsync = ref.read(todayRecordingProvider);
    final serverRecorded = todayAsync.valueOrNull != null;
    final localComplete =
        ref.read(recordingProvider).status == RecordingStatus.complete;
    if (serverRecorded || localComplete) return;

    await _exitController.forward();
    if (mounted) {
      unawaited(context.push(
        RouteNames.recording,
        extra: (_morphController.value, _pulseController.value),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    ref.watch(historyProvider);
    final todayAsync = ref.watch(todayRecordingProvider);

    final todayData = todayAsync.valueOrNull;
    final isServerLoading = todayAsync.isLoading && !todayAsync.hasValue;
    final hasError = todayAsync.hasError && !todayAsync.hasValue;

    final hasRecordedToday =
        todayData != null || recordingState.status == RecordingStatus.complete;
    final todayComplete = todayData?.isComplete == true;
    const streak = 5;

    // Start/stop polling based on recording state
    _startPollingIfNeeded(todayData);

    final showPendingCheck = isServerLoading && !hasRecordedToday;
    final String greeting;
    final String statusText;
    final String subStatus;

    if (hasRecordedToday) {
      greeting = todayComplete ? '¡Día completado!' : 'Procesando tu grabación...';
      statusText = todayComplete
          ? 'Tu clip de hoy está listo'
          : 'Estamos analizando tu audio';
      subStatus = todayComplete
          ? 'Has procesado tus emociones con éxito hoy.'
          : 'Esto tardará solo un momento.';
    } else if (showPendingCheck) {
      greeting = 'Sincronizando tu día...';
      statusText = 'Consultando tu grabación de hoy...';
      subStatus = 'Estamos actualizando tu estado en el servidor.';
    } else if (hasError) {
      greeting = '¿Cómo ha sido tu día?';
      statusText = 'Error al consultar el servidor';
      subStatus = 'Pulsa el botón de abajo para reintentar.';
    } else {
      greeting = '¿Cómo ha sido tu día?';
      statusText = 'Aún no has registrado tu día';
      subStatus = 'Registra tu día para mantener tu racha.';
    }
    final ctaText = hasRecordedToday ? 'Reproducir clip de hoy' : 'Grabar tu día';
    final auraColors = hasRecordedToday
        ? [const Color(0xFF34D399), const Color(0xFF14B8A6), const Color(0xFF06B6D4)]
        : [const Color(0xFF3B82F6), const Color(0xFF6366F1), const Color(0xFF8B5CF6)];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: _exitController.isAnimating
                  ? const NeverScrollableScrollPhysics()
                  : null,
              child: Column(
                children: [
                  SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _exitFade,
                      child: Column(
                        children: [
                          _buildHeader(context, streak),
                          _buildGreeting(greeting),
                        ],
                      ),
                    ),
                  ),

                  _buildAuraVisual(auraColors),

                  SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _exitFade,
                      child: Column(
                        children: [
                          _buildStatsRow(streak, hasRecordedToday),
                          _buildMainCTA(
                            context,
                            statusText,
                            subStatus,
                            ctaText,
                            hasRecordedToday: hasRecordedToday,
                            todayComplete: todayComplete,
                            isLoading: isServerLoading,
                            hasError: hasError,
                            audioUrl: todayData?.audioStreamUrl,
                          ),
                          _buildGoalsCard(context),
                          if (hasRecordedToday)
                            _buildInsightCard(todayData?.insight?.summary),
                          if (hasRecordedToday) _buildHistoryButton(context),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int streak) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Votio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.go(RouteNames.settings),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String greeting) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        greeting,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAuraVisual(List<Color> colors) {
    return GestureDetector(
      onTap: _onBlobTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: 'votio-blob',
        child: SizedBox(
          height: 280,
          width: 280,
          child: AnimatedBuilder(
            animation: Listenable.merge([_morphController, _pulseController]),
            builder: (context, child) {
              return CustomPaint(
                size: const Size(280, 280),
                painter: _BlobPainter(
                  time: _morphController.value,
                  pulse: _pulseController.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Blob painter ─────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  final double time;
  final double pulse;

  const _BlobPainter({required this.time, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.3;

    final path = Path();
    const points = 36;

    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final noise1 = math.sin(angle * 2 + time * 2 * math.pi) * 0.04;
      final noise2 = math.cos(angle * 4 - time * 2 * math.pi) * 0.03;
      final noise3 = math.sin(angle * 6 + time * 4 * math.pi) * 0.02;
      final pulseEffect = 1.0 + math.sin(pulse * 2 * math.pi) * 0.03;
      final radius = baseRadius * (1.0 + noise1 + noise2 + noise3) * pulseEffect;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevAngle = ((i - 1) / points) * 2 * math.pi;
        final prevNoise1 = math.sin(prevAngle * 2 + time * 2 * math.pi) * 0.04;
        final prevNoise2 = math.cos(prevAngle * 4 - time * 2 * math.pi) * 0.03;
        final prevNoise3 = math.sin(prevAngle * 6 + time * 4 * math.pi) * 0.02;
        final prevRadius =
            baseRadius * (1.0 + prevNoise1 + prevNoise2 + prevNoise3) * pulseEffect;
        final prevX = center.dx + math.cos(prevAngle) * prevRadius;
        final prevY = center.dy + math.sin(prevAngle) * prevRadius;
        final midAngle = (angle + prevAngle) / 2;
        final controlRadius = (radius + prevRadius) / 2;
        final controlX = center.dx + math.cos(midAngle) * controlRadius;
        final controlY = center.dy + math.sin(midAngle) * controlRadius;
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }

    path.close();

    final shadowBottomPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
      ..color = const Color(0xFF4C1D95).withOpacity(0.4);
    canvas.save();
    canvas.translate(0, 8);
    canvas.drawPath(path, shadowBottomPaint);
    canvas.restore();

    final shadowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45)
      ..color = const Color(0xFF6366F1).withOpacity(0.25);
    canvas.drawPath(path, shadowPaint);

    final lightDirection = Offset(
      math.sin(time * 2 * math.pi) * 0.3,
      -0.4 + math.cos(time * 2 * math.pi) * 0.2,
    );

    final gradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(
          center.dx + lightDirection.dx * baseRadius,
          center.dy + lightDirection.dy * baseRadius,
        ),
        baseRadius * 1.4,
        [
          const Color(0xFFE0E7FF),
          const Color(0xFFC7D2FE),
          const Color(0xFFA5B4FC),
          const Color(0xFF8B5CF6).withOpacity(0.6),
        ],
        [0.0, 0.4, 0.7, 1.0],
      );
    canvas.drawPath(path, gradientPaint);

    final innerShadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(
          center.dx - lightDirection.dx * baseRadius * 0.8,
          center.dy - lightDirection.dy * baseRadius * 0.8,
        ),
        baseRadius * 1.2,
        [
          Colors.transparent,
          const Color(0xFF4C1D95).withOpacity(0.15),
          const Color(0xFF4C1D95).withOpacity(0.25),
        ],
        [0.0, 0.6, 1.0],
      )
      ..blendMode = BlendMode.multiply;
    canvas.drawPath(path, innerShadowPaint);

    final highlightPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35)
      ..shader = ui.Gradient.radial(
        Offset(
          center.dx + lightDirection.dx * baseRadius * 0.5,
          center.dy + lightDirection.dy * baseRadius * 0.5,
        ),
        baseRadius * 0.8,
        [
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      )
      ..blendMode = BlendMode.screen;
    canvas.drawPath(path, highlightPaint);

    final light1Offset = Offset(
      center.dx - 30 + math.sin(time * 2 * math.pi) * 15,
      center.dy - 40 + math.cos(time * 2 * math.pi) * 15,
    );
    final light1Paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
      ..shader = ui.Gradient.radial(
        light1Offset, 60,
        [
          const Color(0xFFDDD6FE).withOpacity(0.8),
          const Color(0xFFA78BFA).withOpacity(0.4),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(light1Offset, 60, light1Paint);

    final light2Offset = Offset(
      center.dx + 25 + math.cos(time * 4 * math.pi) * 12,
      center.dy + 30 + math.sin(time * 4 * math.pi) * 12,
    );
    final light2Paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35)
      ..shader = ui.Gradient.radial(
        light2Offset, 45,
        [
          const Color(0xFFC7D2FE).withOpacity(0.6),
          const Color(0xFF818CF8).withOpacity(0.2),
          Colors.transparent,
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawCircle(light2Offset, 45, light2Paint);

    final light3Offset = Offset(
      center.dx + math.sin(time * 2 * math.pi + math.pi) * 10,
      center.dy + 10 + math.cos(time * 2 * math.pi + math.pi) * 10,
    );
    final light3Paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
      ..shader = ui.Gradient.radial(
        light3Offset, 50,
        [
          const Color(0xFFE0E7FF).withOpacity(0.5),
          const Color(0xFFA5B4FC).withOpacity(0.15),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(light3Offset, 50, light3Paint);

    final overlayPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - baseRadius, center.dy - baseRadius),
        Offset(center.dx + baseRadius, center.dy + baseRadius),
        [
          const Color(0xFFE0E7FF).withOpacity(0.3),
          Colors.transparent,
          const Color(0xFFC7D2FE).withOpacity(0.2),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.screen;
    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.pulse != pulse;
}

// ─── Extension methods ────────────────────────────────────────────────────────

extension _HomeScreenStateMethods on _HomeScreenState {
  Widget _buildGoalsCard(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final count = goalsState.goals.length;
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push(RouteNames.goals),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151518),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.track_changes,
                  color: Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis Objetivos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$count objetivo${count == 1 ? "" : "s"} activo${count == 1 ? "" : "s"}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[700], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int streak, bool hasRecorded) {
    final progress = hasRecorded ? 100 : 85;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                'RACHA DIARIA',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'días',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            color: Colors.white.withOpacity(0.05),
          ),
          Column(
            children: [
              Text(
                'PROGRESO',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[600], size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCTA(
    BuildContext context,
    String statusText,
    String subStatus,
    String ctaText, {
    required bool hasRecordedToday,
    required bool todayComplete,
    required bool isLoading,
    required bool hasError,
    String? audioUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subStatus,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (isLoading && !hasRecordedToday) ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
          ] else if (hasError && !hasRecordedToday) ...[
            GestureDetector(
              onTap: _refreshToday,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151518),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Colors.grey[400], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Reintentar',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (hasRecordedToday && todayComplete) ...[
            JournalAudioPlayer(audioUrl: audioUrl),
          ] else if (hasRecordedToday && !todayComplete) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF151518),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Procesando tu audio...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            GestureDetector(
              onTap: () => context.push(RouteNames.recording),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Grabar tu día',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String? summary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights Emocionales',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'TU RESUMEN MÁS RECIENTE',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF151518),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF6366F1), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'REFLEXIÓN RÁPIDA',
                          style: TextStyle(
                            color: const Color(0xFF6366F1),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      summary?.trim().isNotEmpty == true
                          ? summary!
                          : 'Tu entrada ha sido registrada. Los insights estarán disponibles en breve.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(RouteNames.history),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151518),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today, color: Colors.grey[500], size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Ver historial completo',
              style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[700], size: 18),
          ],
        ),
      ),
    );
  }

}
