package com.votio.votio_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var silentRecorder: SilentAudioRecorder? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        silentRecorder = SilentAudioRecorder(flutterEngine)
    }

    override fun onDestroy() {
        silentRecorder?.dispose()
        super.onDestroy()
    }
}
