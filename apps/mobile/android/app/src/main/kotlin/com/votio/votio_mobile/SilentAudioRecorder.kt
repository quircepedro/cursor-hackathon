package com.votio.votio_mobile

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Records audio to an M4A (AAC-LC) file using Android's AudioRecord API
 * **without requesting audio focus**. This allows SpeechRecognizer to keep
 * its audio session uninterrupted while we capture audio in parallel.
 *
 * The standard `record` Flutter package calls requestAudioFocus() which sends
 * AUDIOFOCUS_LOSS_TRANSIENT to SpeechRecognizer, killing live transcription.
 */
class SilentAudioRecorder(flutterEngine: FlutterEngine) :
    MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "com.votio/silent_recorder"
        private const val SAMPLE_RATE = 44100
        private const val BIT_RATE = 128000
    }

    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger, CHANNEL
    )

    private var audioRecord: AudioRecord? = null
    private var encoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var recordingThread: Thread? = null
    private val isRecording = AtomicBoolean(false)
    private var outputPath: String? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARG", "path is required", null)
                    return
                }
                start(path, result)
            }
            "stop" -> stop(result)
            "isRecording" -> result.success(isRecording.get())
            else -> result.notImplemented()
        }
    }

    private fun start(path: String, result: MethodChannel.Result) {
        if (isRecording.get()) {
            result.error("ALREADY_RECORDING", "Already recording", null)
            return
        }

        outputPath = path

        try {
            val bufferSize = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            // Create AudioRecord WITHOUT requesting audio focus.
            // This is the key difference from the `record` package.
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize * 2
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                result.error("INIT_FAILED", "AudioRecord failed to initialize", null)
                audioRecord?.release()
                audioRecord = null
                return
            }

            // Set up AAC encoder
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC, SAMPLE_RATE, 1
            ).apply {
                setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
                setInteger(
                    MediaFormat.KEY_AAC_PROFILE,
                    MediaCodecInfo.CodecProfileLevel.AACObjectLC
                )
            }

            encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            encoder!!.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)

            // Ensure parent directory exists
            File(path).parentFile?.mkdirs()

            muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            isRecording.set(true)
            audioRecord!!.startRecording()
            encoder!!.start()

            recordingThread = Thread { encodeLoop() }
            recordingThread!!.start()

            result.success(null)
        } catch (e: Exception) {
            cleanup()
            result.error("START_FAILED", e.message, null)
        }
    }

    private fun encodeLoop() {
        val bufferSize = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val pcmBuffer = ByteArray(bufferSize)
        val bufferInfo = MediaCodec.BufferInfo()
        var trackIndex = -1
        var muxerStarted = false

        while (isRecording.get()) {
            // Read PCM data from mic
            val bytesRead = audioRecord?.read(pcmBuffer, 0, pcmBuffer.size) ?: -1
            if (bytesRead <= 0) continue

            // Feed to encoder in chunks that fit the input buffer
            var offset = 0
            while (offset < bytesRead) {
                val inputIndex = encoder?.dequeueInputBuffer(10_000) ?: -1
                if (inputIndex < 0) break
                val inputBuffer = encoder!!.getInputBuffer(inputIndex)!!
                inputBuffer.clear()
                val chunkSize = minOf(bytesRead - offset, inputBuffer.remaining())
                inputBuffer.put(pcmBuffer, offset, chunkSize)
                encoder!!.queueInputBuffer(inputIndex, 0, chunkSize, 0, 0)
                offset += chunkSize
            }

            // Drain encoded output
            while (true) {
                val outputIndex = encoder?.dequeueOutputBuffer(bufferInfo, 0) ?: -1
                if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    if (!muxerStarted) {
                        trackIndex = muxer!!.addTrack(encoder!!.outputFormat)
                        muxer!!.start()
                        muxerStarted = true
                    }
                } else if (outputIndex >= 0) {
                    if (!muxerStarted) {
                        // Skip until muxer is ready
                        encoder!!.releaseOutputBuffer(outputIndex, false)
                        continue
                    }
                    val outputBuffer = encoder!!.getOutputBuffer(outputIndex)!!
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        encoder!!.releaseOutputBuffer(outputIndex, false)
                        continue
                    }
                    outputBuffer.position(bufferInfo.offset)
                    outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                    muxer!!.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                    encoder!!.releaseOutputBuffer(outputIndex, false)
                } else {
                    break
                }
            }
        }

        // Signal EOS and drain remaining
        try {
            val eosIndex = encoder?.dequeueInputBuffer(10_000) ?: -1
            if (eosIndex >= 0) {
                encoder!!.queueInputBuffer(
                    eosIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM
                )
            }
            // Drain remaining encoded data
            while (true) {
                val outputIndex = encoder?.dequeueOutputBuffer(bufferInfo, 10_000) ?: -1
                if (outputIndex >= 0) {
                    if (muxerStarted && bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                        val outputBuffer = encoder!!.getOutputBuffer(outputIndex)!!
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer!!.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                    }
                    encoder!!.releaseOutputBuffer(outputIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                } else {
                    break
                }
            }
        } catch (_: Exception) {
            // Ignore errors during EOS flush
        }

        cleanup()
    }

    private fun stop(result: MethodChannel.Result) {
        if (!isRecording.get()) {
            result.success(outputPath)
            return
        }
        isRecording.set(false)
        try {
            recordingThread?.join(3000)
        } catch (_: InterruptedException) {
            // timeout is fine
        }
        result.success(outputPath)
    }

    private fun cleanup() {
        try { audioRecord?.stop() } catch (_: Exception) {}
        try { audioRecord?.release() } catch (_: Exception) {}
        audioRecord = null

        try { encoder?.stop() } catch (_: Exception) {}
        try { encoder?.release() } catch (_: Exception) {}
        encoder = null

        try { muxer?.stop() } catch (_: Exception) {}
        try { muxer?.release() } catch (_: Exception) {}
        muxer = null

        recordingThread = null
    }

    fun dispose() {
        isRecording.set(false)
        try { recordingThread?.join(2000) } catch (_: Exception) {}
        cleanup()
        channel.setMethodCallHandler(null)
    }
}
