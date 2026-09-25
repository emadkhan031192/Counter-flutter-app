package com.afzal.zikr

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.util.Calendar

object ReminderScheduler {

    private fun pendingIntent(ctx: Context): PendingIntent {
        val intent = Intent(ctx, ReminderReceiver::class.java)
        return PendingIntent.getBroadcast(
            ctx, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun nextTrigger(hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, hour)
        cal.set(Calendar.MINUTE, minute)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        if (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }

    /** Schedules (or re-schedules) the next single firing at hour:minute. */
    fun schedule(ctx: Context, hour: Int, minute: Int) {
        Prefs.setReminder(ctx, enabled = true, hour = hour, minute = minute)
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = nextTrigger(hour, minute)
        try {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent(ctx))
        } catch (e: SecurityException) {
            // Exact alarms not permitted (rare OEM/policy case) - fall back to inexact.
            am.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent(ctx))
        }
    }

    fun cancel(ctx: Context) {
        Prefs.setReminder(ctx, enabled = false, hour = Prefs.reminderHour(ctx), minute = Prefs.reminderMinute(ctx))
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(ctx))
    }

    /** Called after the alarm fires, and from BootReceiver, to re-arm the next day. */
    fun rescheduleIfEnabled(ctx: Context) {
        if (Prefs.reminderEnabled(ctx)) {
            schedule(ctx, Prefs.reminderHour(ctx), Prefs.reminderMinute(ctx))
        }
    }
}
