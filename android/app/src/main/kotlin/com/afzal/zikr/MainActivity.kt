package com.afzal.zikr

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.view.KeyEvent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.afzal.zikr/native"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVolumeCounting" -> {
                    val useVolumeUp = call.argument<Boolean>("useVolumeUp") ?: false
                    Prefs.setVolumeCountingEnabled(this, true)
                    Prefs.setUseVolumeUp(this, useVolumeUp)
                    ContextCompat.startForegroundService(
                        this, Intent(this, ForegroundCountingService::class.java)
                    )
                    result.success(null)
                }
                "stopVolumeCounting" -> {
                    Prefs.setVolumeCountingEnabled(this, false)
                    stopService(Intent(this, ForegroundCountingService::class.java))
                    result.success(null)
                }
                "isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled())
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "takePendingCount" -> result.success(Prefs.takePendingCount(this))
                "scheduleReminder" -> {
                    val hour = call.argument<Int>("hour") ?: 20
                    val minute = call.argument<Int>("minute") ?: 0
                    ReminderScheduler.schedule(this, hour, minute)
                    result.success(null)
                }
                "cancelReminder" -> {
                    ReminderScheduler.cancel(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Prefs.setAppForeground(this, true)
    }

    override fun onPause() {
        Prefs.setAppForeground(this, false)
        super.onPause()
    }

    /** Handles the chosen volume key directly while the app is on screen,
     * for an instant tick, and swallows it so the volume UI never shows. */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (Prefs.isVolumeCountingEnabled(this)) {
            val wantsUp = Prefs.useVolumeUp(this)
            val targetCode = if (wantsUp) KeyEvent.KEYCODE_VOLUME_UP else KeyEvent.KEYCODE_VOLUME_DOWN
            if (event.keyCode == targetCode) {
                if (event.action == KeyEvent.ACTION_DOWN) {
                    channel?.invokeMethod("onVolumeTick", null)
                }
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, VolumeKeyAccessibilityService::class.java).flattenToString()
        val enabledServices = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.split(':').any { it.equals(expected, ignoreCase = true) }
    }
}
