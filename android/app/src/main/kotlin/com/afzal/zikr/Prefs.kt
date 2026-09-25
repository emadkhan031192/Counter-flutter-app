package com.afzal.zikr

import android.content.Context
import android.content.SharedPreferences

/** Small wrapper around the SharedPreferences file every native class shares. */
object Prefs {
    private const val FILE = "zikr_native_prefs"

    private fun sp(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun setVolumeCountingEnabled(ctx: Context, enabled: Boolean) =
        sp(ctx).edit().putBoolean("volume_counting_enabled", enabled).apply()

    fun isVolumeCountingEnabled(ctx: Context): Boolean =
        sp(ctx).getBoolean("volume_counting_enabled", false)

    fun setUseVolumeUp(ctx: Context, useUp: Boolean) =
        sp(ctx).edit().putBoolean("use_volume_up", useUp).apply()

    fun useVolumeUp(ctx: Context): Boolean = sp(ctx).getBoolean("use_volume_up", false)

    fun setAppForeground(ctx: Context, foreground: Boolean) =
        sp(ctx).edit().putBoolean("app_foreground", foreground).apply()

    fun isAppForeground(ctx: Context): Boolean = sp(ctx).getBoolean("app_foreground", false)

    /** Screen-off / backgrounded ticks queued by the accessibility service. */
    @Synchronized
    fun addPendingCount(ctx: Context, amount: Int = 1) {
        val current = sp(ctx).getInt("pending_count", 0)
        sp(ctx).edit().putInt("pending_count", current + amount).apply()
    }

    @Synchronized
    fun takePendingCount(ctx: Context): Int {
        val current = sp(ctx).getInt("pending_count", 0)
        if (current != 0) sp(ctx).edit().putInt("pending_count", 0).apply()
        return current
    }

    fun setReminder(ctx: Context, enabled: Boolean, hour: Int, minute: Int) {
        sp(ctx).edit()
            .putBoolean("reminder_enabled", enabled)
            .putInt("reminder_hour", hour)
            .putInt("reminder_minute", minute)
            .apply()
    }

    fun reminderEnabled(ctx: Context): Boolean = sp(ctx).getBoolean("reminder_enabled", false)
    fun reminderHour(ctx: Context): Int = sp(ctx).getInt("reminder_hour", 20)
    fun reminderMinute(ctx: Context): Int = sp(ctx).getInt("reminder_minute", 0)
}
