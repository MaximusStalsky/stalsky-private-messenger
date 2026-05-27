package com.example.messenger_app

import android.content.ContentValues
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var incomingCallRingtone: Ringtone? = null
    private val ringtoneHandler = Handler(Looper.getMainLooper())
    private val replayRingtone = object : Runnable {
        override fun run() {
            incomingCallRingtone?.let { ringtone ->
                if (!ringtone.isPlaying) ringtone.play()
                ringtoneHandler.postDelayed(this, 2000)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "messenger_app/call_notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startIncomingCallRingtone" -> {
                        startIncomingCallRingtone()
                        result.success(null)
                    }
                    "stopIncomingCallRingtone" -> {
                        stopIncomingCallRingtone()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "messenger_app/media")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveImageToGallery" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "my_messenger_image.jpg"
                        val mimeType = call.argument<String>("mimeType") ?: "image/jpeg"
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("invalid_image", "Image data is empty", null)
                        } else {
                            try {
                                saveImageToGallery(bytes, fileName, mimeType)
                                result.success(null)
                            } catch (error: Exception) {
                                result.error("save_failed", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveImageToGallery(bytes: ByteArray, fileName: String, mimeType: String) {
        val safeName = fileName.replace(Regex("[\\\\/:*?\"<>|]"), "_")
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, safeName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/My Messenger")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create image")
        try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: throw IllegalStateException("Could not open image output stream")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
            }
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    private fun startIncomingCallRingtone() {
        stopIncomingCallRingtone()
        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: return
        incomingCallRingtone = RingtoneManager.getRingtone(applicationContext, ringtoneUri)?.apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
            }
            play()
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            ringtoneHandler.postDelayed(replayRingtone, 2000)
        }
    }

    private fun stopIncomingCallRingtone() {
        ringtoneHandler.removeCallbacks(replayRingtone)
        incomingCallRingtone?.stop()
        incomingCallRingtone = null
    }
}
