package com.afzal.zikr

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

object Notifications {
    const val COUNTING_CHANNEL = "zikr_counting_active"
    const val REMINDER_CHANNEL = "zikr_reminder"
    const val COUNTING_NOTIFICATION_ID = 1001
    const val REMINDER_NOTIFICATION_ID = 1002

    fun ensureChannels(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        nm.createNotificationChannel(
            NotificationChannel(
                COUNTING_CHANNEL,
                "Volume-button counting",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shown while counting with the volume button is active"
            }
        )

        nm.createNotificationChannel(
            NotificationChannel(
                REMINDER_CHANNEL,
                "Dhikr reminder",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Your daily dhikr reminder"
            }
        )
    }

    fun countingActiveNotification(ctx: Context, useVolumeUp: Boolean): Notification {
        ensureChannels(ctx)
        val button = if (useVolumeUp) "Up" else "Down"
        return NotificationCompat.Builder(ctx, COUNTING_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle("Zikr counting active")
            .setContentText("Volume $button to count")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    fun reminderNotification(ctx: Context): Notification {
        ensureChannels(ctx)
        return NotificationCompat.Builder(ctx, REMINDER_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle("Time for your Zikr \uD83E\uDD32")
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
    }
}
