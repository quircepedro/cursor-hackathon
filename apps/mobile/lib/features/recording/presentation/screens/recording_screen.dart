import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/services/journal_audio_storage.dart';
import '../../../../core/services/silent_audio_recorder.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({
    super.key,
    this.initialMorphTime = 0.0,
    this.initialPulseTime = 0.0,
  });

  final double initialMorphTime;
  final double initialPulseTime;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _morphController;
  late final AnimationController _pulseController;
  late final AnimationController _colorController;

  final _speech = SpeechToText();
  final _audioRecorder = AudioRecorder();
  final _silentRecorder = SilentAudioRecorder(); // Android (no audio focus)
  final _audioStorage = JournalAudioStorage();
  bool _speechAvailable = false;
  bool _isRecording = false;
  bool _isBusy = false;
  bool _isRestarting = false; // prevents re-entrant restart loops
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  Timer? _restartTimer;
  Timer? _watchdog; // periodic check to ensure speech is alive

  // Sound level for blob reactivity (0.0 – 1.0)
  double _soundLevel = 0.0;

  // Transcript accumulation
  String _finalTranscript = '';
  String _currentPartial = '';

  String get _fullTranscript {
    if (_finalTranscript.isEmpty) return _currentPartial;
    if (_currentPartial.isEmpty) return _finalTranscript;
    return '$_finalTranscript $_currentPartial';
  }

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
      value: widget.initialMorphTime,
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      value: widget.initialPulseTime,
    )..repeat();
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (mounted) setState(() {});
  }

  void _onSpeechStatus(String status) {
    if (!_isRecording || _isRestarting) return;
    if (status == SpeechToText.notListeningStatus) {
      _scheduleRestart();
    }
  }

  void _onSpeechError(dynamic error) {
    // On Android, errors like error_speech_timeout / error_no_match fire
    // instead of (or in addition to) notListeningStatus.
    if (!_isRecording || _isRestarting) return;
    _scheduleRestart();
  }

  void _scheduleRestart() {
    // Debounce: both onError and onStatus can fire for the same event.
    // Cancel any pending restart and schedule a single one.
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isRecording || !mounted) return;
      _doRestart();
    });
  }

  Future<void> _doRestart() async {
    if (_isRestarting) return;
    _isRestarting = true;

    // Commit any partial text before restarting
    if (_currentPartial.isNotEmpty) {
      setState(() {
        _finalTranscript = _fullTranscript;
        _currentPartial = '';
      });
    }

    try {
      await _startListening();
    } finally {
      _isRestarting = false;
    }
  }

  String? get _deviceLocale {
    final locale = ui.PlatformDispatcher.instance.locale;
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      return '${locale.languageCode}_$country';
    }
    // If no country code, let the engine pick its default for the language
    return null;
  }

  bool get _isAndroidNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _onSoundLevel(double level) {
    if (!mounted) return;
    // iOS: roughly -2 to 10 dB, Android: 0 to ~30 dB
    // Normalize to 0.0 – 1.0 with smooth clamping
    final normalized = ((level + 2) / 15).clamp(0.0, 1.0);
    // Smooth: move 30% toward new value each frame for organic feel
    setState(() {
      _soundLevel = _soundLevel + (normalized - _soundLevel) * 0.3;
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !_isRecording) return;
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          if (result.finalResult) {
            if (result.recognizedWords.isNotEmpty) {
              _finalTranscript = _finalTranscript.isEmpty
                  ? result.recognizedWords
                  : '$_finalTranscript ${result.recognizedWords}';
            }
            _currentPartial = '';
          } else {
            _currentPartial = result.recognizedWords;
          }
        });
      },
      onSoundLevelChange: _onSoundLevel,
      localeId: _deviceLocale,
      listenFor: const Duration(seconds: 59),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    _restartTimer?.cancel();
    _watchdog?.cancel();
    _colorController.dispose();
    _speech.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      _isRecording ? await _stop() : await _start();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _start() async {
    // Re-initialize speech if the first attempt (in initState) failed —
    // this happens on Android when the mic permission had not been granted yet
    // at screen-load time. initialize() is cheap to call again once granted.
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    }

    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
      _finalTranscript = '';
      _currentPartial = '';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    // Watchdog: every 3s check if speech is alive, restart if not
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isRecording || !mounted || _isRestarting) return;
      if (!_speech.isListening) {
        _doRestart();
      }
    });
    _colorController.repeat(reverse: true);

    final tempPath = await _audioStorage.pathForToday();
    if (_isAndroidNative) {
      // On Android the `record` package calls requestAudioFocus() which sends
      // AUDIOFOCUS_LOSS_TRANSIENT to SpeechRecognizer, killing transcription.
      // SilentAudioRecorder uses AudioRecord + MediaCodec directly without
      // requesting audio focus, so both can share the microphone.
      await _silentRecorder.start(tempPath);
    } else {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
          ),
          path: tempPath,
        );
      }
    }

    await _startListening();
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _restartTimer?.cancel();
    _watchdog?.cancel();
    _isRestarting = false;
    _colorController.stop();
    _colorController.animateTo(0.0, duration: const Duration(seconds: 2));
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });
    await _speech.stop();

    // Stop audio file recording
    if (_isAndroidNative) {
      await _silentRecorder.stop();
    } else {
      if (await _audioRecorder.isRecording()) {
        final recordedPath = await _audioRecorder.stop();
        if (kIsWeb && recordedPath != null && recordedPath.isNotEmpty) {
          await _audioStorage.saveToday(recordedPath);
        }
      }
    }

    if (!mounted) return;
    final transcript = _fullTranscript.trim();
    context.pushReplacement(
      RouteNames.transcriptionReview,
      extra: transcript,
    );
  }

  String get _timeLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                const SizedBox(height: 60),
                // Blob
                GestureDetector(
                  onTap: _toggleRecording,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Hero(
                      tag: 'votio-blob',
                      child: SizedBox(
                        width: 280,
                        height: 280,
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_morphController, _pulseController, _colorController]),
                          builder: (_, __) => CustomPaint(
                            size: const Size(280, 280),
                            painter: _BlobPainter(
                              time: _morphController.value,
                              pulse: _pulseController.value,
                              isRecording: _isRecording,
                              soundLevel: _soundLevel,
                              colorShift: _colorController.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Timer
                Text(
                  _timeLabel,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRecording ? 'Recording...' : 'Tap to start',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const Spacer(),
                // Mic button
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Back button overlay
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () {
                  if (_isRecording) return;
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
            // Title overlay
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Record',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Blob painter ─────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  final double time;
  final double pulse;
  final bool isRecording;
  final double soundLevel; // 0.0 – 1.0
  final double colorShift; // 0.0 indigo → 1.0 orange
  const _BlobPainter({
    required this.time,
    required this.pulse,
    this.isRecording = false,
    this.soundLevel = 0.0,
    this.colorShift = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Base radius grows with sound: up to 30% larger when loud
    final rBase = size.width * 0.3;
    final r = isRecording ? rBase * (1.0 + soundLevel * 0.30) : rBase;
    final path = Path();
    const n = 80;
    final m = isRecording ? 1.0 + soundLevel * 2.0 : 1.0;
    final pulseAmp = isRecording ? 0.03 + soundLevel * 0.08 : 0.03;
    final pe = 1.0 + math.sin(pulse * 2 * math.pi) * pulseAmp;
    final t2 = time * 2 * math.pi;
    final t4 = time * 4 * math.pi;

    // Pre-compute all points on the blob
    final pts = List<Offset>.generate(n, (i) {
      final a = (i / n) * 2 * math.pi;
      final rad = r *
          (1.0 +
              math.sin(a * 2 + t2) * 0.04 * m +
              math.cos(a * 4 - t2) * 0.03 * m +
              math.sin(a * 6 + t4) * 0.02 * m) *
          pe;
      return Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
    });

    // Build smooth closed path using cubic Bézier (Catmull-Rom → cubic)
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
    path.close();

    canvas.save();
    canvas.translate(0, 8);
    canvas.drawPath(
        path,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
          ..color = Color.lerp(const Color(0xFF4C1D95), const Color(0xFF7A3B10), colorShift)!
              .withOpacity(0.4));
    canvas.restore();

    canvas.drawPath(
        path,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45)
          ..color = Color.lerp(const Color(0xFF6366F1), const Color(0xFFF97316), colorShift)!
              .withOpacity(0.25));

    final ld = Offset(math.sin(time * 2 * math.pi) * 0.3,
        -0.4 + math.cos(time * 2 * math.pi) * 0.2);
    final t = colorShift;
    canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.radial(
              Offset(c.dx + ld.dx * r, c.dy + ld.dy * r),
              r * 1.4,
              [
                Color.lerp(const Color(0xFFE0E7FF), const Color(0xFFFFF7ED), t)!,
                Color.lerp(const Color(0xFFC7D2FE), const Color(0xFFFDBA74), t)!,
                Color.lerp(const Color(0xFFA5B4FC), const Color(0xFFF97316), t)!,
                Color.lerp(const Color(0xFF8B5CF6), const Color(0xFFC2410C), t)!.withOpacity(0.6),
              ],
              [0.0, 0.4, 0.7, 1.0]));

    canvas.drawPath(
        path,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35)
          ..shader = ui.Gradient.radial(
              Offset(c.dx + ld.dx * r * 0.5, c.dy + ld.dy * r * 0.5),
              r * 0.8,
              [
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.3),
                Colors.transparent
              ],
              [0.0, 0.4, 1.0])
          ..blendMode = BlendMode.screen);
  }

  @override
  bool shouldRepaint(_BlobPainter o) =>
      o.time != time ||
      o.pulse != pulse ||
      o.isRecording != isRecording ||
      o.soundLevel != soundLevel ||
      o.colorShift != colorShift;
}
