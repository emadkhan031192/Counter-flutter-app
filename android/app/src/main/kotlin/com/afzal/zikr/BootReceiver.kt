package com.afzal.zikr

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        ReminderScheduler.rescheduleIfEnabled(context)

        // The app was in the foreground when the device rebooted, so that
        // flag is now stale - clear it.
        Prefs.setAppForeground(context, false)

        if (Prefs.isVolumeCountingEnabled(context)) {
            val svcIntent = Intent(context, ForegroundCountingService::class.java)
            ContextCompat.startForegroundService(context, svcIntent)
        }
    }
}
