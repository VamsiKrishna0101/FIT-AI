package com.example.fitai_mobile

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.SleepSegmentEvent
import com.google.android.gms.location.SleepSegmentRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/** No microphone/location access. Google delivers low-power sleep segments. */
class PhoneSleepTracking(private val activity: Activity) {
    companion object {
        const val PERMISSION_REQUEST = 7314
        fun prefs(context: Context) = context.getSharedPreferences("fitai_phone_sleep", Context.MODE_PRIVATE)
        fun records(context: Context, owner: String): JSONArray = try {
            JSONArray(prefs(context).getString("${owner}_records", "[]"))
        } catch (_: Exception) { JSONArray() }
        fun pending(context: Context, owner: String): PendingIntent {
            val intent = Intent(context, PhoneSleepReceiver::class.java)
                .setAction("${context.packageName}.PHONE_SLEEP")
                .setData(Uri.parse("fitai-sleep://account/${Uri.encode(owner)}"))
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
            return PendingIntent.getBroadcast(context, 0, intent, flags)
        }
        fun stop(context: Context, owner: String, forgetConsent: Boolean = true): com.google.android.gms.tasks.Task<Void>? {
            val settings = prefs(context)
            val edit = settings.edit().putBoolean("${owner}_active", false)
                .putLong("${owner}_generation", settings.getLong("${owner}_generation", 0) + 1)
                .remove("${owner}_records").remove("${owner}_since")
            if (forgetConsent) edit.putBoolean("${owner}_consent", false)
            edit.apply()
            return try { ActivityRecognition.getClient(context).removeSleepSegmentUpdates(pending(context, owner)) }
            catch (_: Exception) { null /* Receiver also rejects stopped subscriptions. */ }
        }
    }
    private var waiting: Pair<String, MethodChannel.Result>? = null
    private val settings get() = prefs(activity)
    private fun allowed(owner: String) = settings.getString("owner", null) == owner &&
        settings.getString("${owner}_usage", "UNKNOWN") == "NONE"

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        val owner = call.argument<String>("owner")
        if (call.method == "sessionOwner") {
            val previous = settings.getString("owner", null)
            if (previous != owner && previous != null) stop(activity, previous, forgetConsent = false)
            settings.edit().putString("owner", owner).apply()
            if (previous != owner) { waiting?.second?.success(false); waiting = null }
            result.success(null); return
        }
        if (owner.isNullOrBlank() || settings.getString("owner", null) != owner) {
            result.error("SESSION_CHANGED", "Sign in again to manage phone sleep.", null); return
        }
        when (call.method) {
            "setUsage" -> {
                val usage = call.argument<String>("usage") ?: "UNKNOWN"
                if (usage !in listOf("NONE", "WEARABLE", "UNKNOWN")) {
                    result.error("INVALID", "Choose a wearable preference.", null); return
                }
                settings.edit().putString("${owner}_usage", usage).apply()
                if (usage != "NONE") stop(activity, owner)
                result.success(null)
            }
            "enabled" -> result.success(allowed(owner) && hasPermission() && settings.getBoolean("${owner}_active", false))
            "estimates" -> {
                if (!allowed(owner) || !hasPermission() || !settings.getBoolean("${owner}_active", false)) {
                    result.success(emptyList<Map<String, Long>>()); return
                }
                val records = records(activity, owner)
                val cutoff = System.currentTimeMillis() - 7 * 86400000L
                val retained = (0 until records.length()).mapNotNull { records.optJSONObject(it) }
                    .filter { it.optLong("end") >= cutoff }
                settings.edit().putString("${owner}_records", JSONArray(retained).toString()).apply()
                result.success(retained.map { mapOf("start" to it.optLong("start"), "end" to it.optLong("end")) })
            }
            "stop" -> {
                waiting?.second?.success(false); waiting = null
                val stopping = stop(activity, owner)
                if (stopping == null) result.success(null)
                else stopping.addOnCompleteListener { result.success(null) }
            }
            "resume" -> {
                // Re-register after app upgrades/reboots only with existing consent.
                if (allowed(owner) && hasPermission() && settings.getBoolean("${owner}_consent", false)) start(owner, result)
                else result.success(false)
            }
            "start" -> {
                if (!allowed(owner)) { result.success(false); return }
                if (waiting != null) { result.error("BUSY", "Permission request is already open.", null); return }
                if (GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(activity) != ConnectionResult.SUCCESS) {
                    result.error("UNAVAILABLE", "Phone sleep estimation needs Google Play services. You can enter sleep instead.", null); return
                }
                if (!hasPermission()) {
                    waiting = owner to result
                    ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.ACTIVITY_RECOGNITION), PERMISSION_REQUEST)
                } else start(owner, result)
            }
            else -> result.notImplemented()
        }
    }
    private fun hasPermission() = Build.VERSION.SDK_INT < 29 ||
        ContextCompat.checkSelfPermission(activity, Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED
    fun permissionResult(requestCode: Int) {
        if (requestCode != PERMISSION_REQUEST) return
        val request = waiting ?: return
        waiting = null
        if (hasPermission() && allowed(request.first)) start(request.first, request.second)
        else request.second.success(false)
    }
    private fun start(owner: String, result: MethodChannel.Result) {
        if (!allowed(owner)) { result.success(false); return }
        val subscription = pending(activity, owner)
        val generation = settings.getLong("${owner}_generation", 0)
        try {
            ActivityRecognition.getClient(activity).requestSleepSegmentUpdates(subscription,
                SleepSegmentRequest(SleepSegmentRequest.SEGMENT_EVENTS_ONLY))
                .addOnSuccessListener {
                    if (!allowed(owner) || generation != settings.getLong("${owner}_generation", 0)) {
                        ActivityRecognition.getClient(activity).removeSleepSegmentUpdates(subscription)
                        result.success(false)
                    } else {
                        val since = settings.getLong("${owner}_since", System.currentTimeMillis())
                        settings.edit().putBoolean("${owner}_active", true).putBoolean("${owner}_consent", true)
                            .putLong("${owner}_since", since).apply()
                        result.success(true)
                    }
                }.addOnFailureListener {
                    settings.edit().putBoolean("${owner}_active", false).apply()
                    result.error("UNAVAILABLE", "Could not start phone sleep estimation. You can enter sleep instead.", null)
                }
        } catch (_: Exception) { result.error("UNAVAILABLE", "Phone sleep estimation is unavailable.", null) }
    }
}

class PhoneSleepReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val owner = intent.data?.lastPathSegment ?: return
        val settings = PhoneSleepTracking.prefs(context)
        if (settings.getString("owner", null) != owner || settings.getString("${owner}_usage", null) != "NONE" ||
            !settings.getBoolean("${owner}_active", false) || !settings.getBoolean("${owner}_consent", false)) return
        if (Build.VERSION.SDK_INT >= 29 && ContextCompat.checkSelfPermission(context, Manifest.permission.ACTIVITY_RECOGNITION) != PackageManager.PERMISSION_GRANTED) return
        if (!SleepSegmentEvent.hasEvents(intent)) return
        val now = System.currentTimeMillis()
        val since = settings.getLong("${owner}_since", now)
        val records = PhoneSleepTracking.records(context, owner)
        val combined = mutableMapOf<Long, JSONObject>()
        for (i in 0 until records.length()) {
            val row = records.getJSONObject(i)
            if (row.getLong("end") >= now - 7 * 86400000L) combined[row.getLong("start")] = row
        }
        for (event in SleepSegmentEvent.extractEvents(intent)) {
            if (event.status != SleepSegmentEvent.STATUS_SUCCESSFUL || event.startTimeMillis < since ||
                event.endTimeMillis > now || event.endTimeMillis <= event.startTimeMillis ||
                event.endTimeMillis - event.startTimeMillis > 86400000L) continue
            combined[event.startTimeMillis] = JSONObject().put("start", event.startTimeMillis).put("end", event.endTimeMillis)
        }
        settings.edit().putString("${owner}_records", JSONArray(combined.values.sortedBy { it.getLong("start") }.takeLast(14)).toString()).apply()
    }
}
