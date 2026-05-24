package com.example.messenger_app

import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
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
