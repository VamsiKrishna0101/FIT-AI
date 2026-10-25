package com.example.fitai_mobile

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.widget.ScrollView
import android.widget.TextView

/** Accessible from Health Connect's permission rationale on Android 9–14+. */
class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Setcraft health privacy"
        val text = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 17f
            val padding = (24 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
            text = "Setcraft health privacy\n\n" +
                "Connecting health is optional. Choose which categories to share, or continue without connecting.\n\n" +
                "Setcraft requests read access to steps, active calories, workouts, sleep. Weight and body fat are optional. Setcraft does not write to Health Connect.\n\n" +
                "With your permission, Setcraft reads available records on this device and uploads daily readings, their source and measurement time, and imported workouts to your signed-in Setcraft account. They are used for Today, Body and Progress. Readiness uses your optional sleep and check-in answers, not heart readings. Missing readings remain empty.\n\n" +
                "Sync runs when you open Setcraft or choose Sync now. Stop syncing in Profile → Health connection, or revoke access in Health Connect. Stopping sync does not delete readings already saved in Setcraft.\n\n" +
                "For people who select that they do not use a wearable, phone sleep estimation is separately optional. With Physical activity permission, Google's Sleep API estimates sleep from device light and motion. Setcraft does not request microphone or location access for this feature. Unconfirmed estimates stay on this device, are excluded from backups and are removed when tracking is stopped or the account changes. Only a sleep estimate you confirm and save is uploaded to your Setcraft account.\n\n" +
                "A daily check-in estimate uses your reported sleep duration, rest, energy and soreness. It does not measure sleep stages, HRV or heart rate. Turn phone estimation off in Log sleep; normal sleep entry remains available."
        }
        setContentView(ScrollView(this).apply {
            setBackgroundColor(Color.rgb(16, 16, 18))
            addView(text)
        })
    }
}
