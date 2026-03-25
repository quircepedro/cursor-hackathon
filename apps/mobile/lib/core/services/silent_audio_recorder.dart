import 'package:flutter/services.dart';

/// Android-only audio recorder that does NOT request audio focus.
/// Uses a platform channel to record via AudioRecord + MediaCodec (AAC-LC)
/// directly, bypassing the `record` package which calls requestAudioFocus()
/// and kills SpeechRecognizer.
class SilentAudioRecorder {
  static const _channel = MethodChannel('com.votio/silent_recorder');

  Future<void> start(String path) async {
    await _channel.invokeMethod('start', {'path': path});
  }

  Future<String?> stop() async {
    return await _channel.invokeMethod<String?>('stop');
  }

  Future<bool> isRecording() async {
    return await _channel.invokeMethod<bool>('isRecording') ?? false;
  }
}
