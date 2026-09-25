package com.afzal.zikr

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!Prefs.reminderEnabled(context)) return
        NotificationManagerCompat.from(context)
            .notify(Notifications.REMINDER_NOTIFICATION_ID, Notifications.reminderNotification(context))
        // Exact alarms are one-shot: arm tomorrow's firing right away.
        ReminderScheduler.schedule(context, Prefs.reminderHour(context), Prefs.reminderMinute(context))
    }
}
