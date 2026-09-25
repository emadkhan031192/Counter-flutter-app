package com.afzal.zikr

import android.accessibilityservice.AccessibilityService
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

/**
 * Consumes the user's chosen volume key so it increments the dhikr count
 * instead of adjusting media volume, while the screen is off/locked or
 * the app is backgrounded. Whenever the app is in the foreground,
 * MainActivity.dispatchKeyEvent handles the same key directly for an
 * instant UI update, and this service steps aside to avoid double counts.
 *
 * Note: delivery of hardware key events to an AccessibilityService while
 * the screen is fully off is not guaranteed identically on every Android
 * OEM/skin. This is the standard, permission-based approach available to
 * a normal (non-system, non-device-owner) app; test on your target
 * devices and see the README for details.
 */
class VolumeKeyAccessibilityService : AccessibilityService() {

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (!Prefs.isVolumeCountingEnabled(applicationContext)) return super.onKeyEvent(event)
        if (Prefs.isAppForeground(applicationContext)) return super.onKeyEvent(event)

        val wantsVolumeUp = Prefs.useVolumeUp(applicationContext)
        val targetKeyCode = if (wantsVolumeUp) KeyEvent.KEYCODE_VOLUME_UP else KeyEvent.KEYCODE_VOLUME_DOWN

        if (event.keyCode == targetKeyCode) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                Prefs.addPendingCount(applicationContext, 1)
            }
            // Consume it either way (DOWN and UP) so the system never
            // shows the volume slider or changes the stream.
            return true
        }
        return super.onKeyEvent(event)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used - we only care about onKeyEvent.
    }

    override fun onInterrupt() {}
}
