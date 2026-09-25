package com.afzal.zikr

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * A minimal foreground service whose only job is to keep a low-priority
 * notification on screen while volume-button counting is armed, and to
 * keep the process alive enough for [VolumeKeyAccessibilityService] to
 * reliably see key events while the screen is off.
 */
class ForegroundCountingService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val useVolumeUp = Prefs.useVolumeUp(this)
        startForeground(
            Notifications.COUNTING_NOTIFICATION_ID,
            Notifications.countingActiveNotification(this, useVolumeUp)
        )
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
