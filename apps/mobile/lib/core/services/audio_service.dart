/// Interface for audio recording and playback.
/// A real implementation (using the `record` package) will be added when
/// the recording feature is built.
abstract class AudioService {
  /// Start recording. Returns true if recording started successfully.
  Future<bool> startRecording();

  /// Stop recording. Returns the file path of the recorded audio.
  Future<String?> stopRecording();

  /// Cancel the current recording without saving.
  Future<void> cancelRecording();

  /// Whether a recording session is active.
  bool get isRecording;

  /// Get current recording duration.
  Duration get currentDuration;

  /// Play audio from a file path or URL.
  Future<void> playAudio(String source);

  /// Stop playback.
  Future<void> stopPlayback();
}

/// Stub implementation — logs operations, returns no real data.
class StubAudioService implements AudioService {
  bool _isRecording = false;
  Duration _duration = Duration.zero;

  @override
  Future<bool> startRecording() async {
    _isRecording = true;
    return true;
  }

  @override
  Future<String?> stopRecording() async {
    _isRecording = false;
    _duration = Duration.zero;
    return null; // No real file in stub
  }

  @override
  Future<void> cancelRecording() async {
    _isRecording = false;
    _duration = Duration.zero;
  }

  @override
  bool get isRecording => _isRecording;

  @override
  Duration get currentDuration => _duration;

  @override
  Future<void> playAudio(String source) async {}

  @override
  Future<void> stopPlayback() async {}
}
