package com.setcraft.app

import android.content.Intent
import android.content.ClipData
import android.content.ClipboardManager
import android.os.PersistableBundle
import android.view.WindowManager
import android.os.Build
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import java.time.Instant

class MainActivity : FlutterFragmentActivity() {
    private lateinit var phoneSleep: PhoneSleepTracking
    private var hydrationTilt: HydrationTiltStream? = null
    private var hydrationEvents: EventChannel? = null
    private var hydrationControl: MethodChannel? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Flutter's first frame draws the same stationary vector mark.
            // Avoid the platform's extra icon fade/translation at that handoff.
            splashScreen.setOnExitAnimationListener { splash -> splash.remove() }
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AccountSettingsBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        hydrationTilt?.dispose()
        val tilt = HydrationTiltStream(this)
        hydrationTilt = tilt
        hydrationEvents = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "setcraft/hydration_motion").also {
            it.setStreamHandler(tilt)
        }
        hydrationControl = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "setcraft/hydration_motion_control").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "isAvailable") result.success(tilt.available) else result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "setcraft/credentials")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "protectScreen" -> {
                        if (call.argument<Boolean>("enabled") == true) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "copyToken" -> {
                        val value = call.argument<String>("value")
                        if (value == null || !value.startsWith("sc_mcp_") || value.length > 150) {
                            result.error("INVALID_TOKEN", "Could not copy this token.", null)
                        } else {
                            val clip = ClipData.newPlainText("Setcraft access token", value)
                            clip.description.extras = PersistableBundle().apply {
                                putBoolean("android.content.extra.IS_SENSITIVE", true)
                            }
                            getSystemService(ClipboardManager::class.java).setPrimaryClip(clip)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        val notifications = getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(NotificationChannel(
            "fitai_reminders", "Setcraft reminders", NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Workout reminders, check-ins and plan updates"
            lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
        })
        notifications.createNotificationChannel(NotificationChannel(
            "setcraft_insights", "Progress insights", NotificationManager.IMPORTANCE_DEFAULT
        ).apply { lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE })
        notifications.createNotificationChannel(NotificationChannel(
            "setcraft_account", "Account updates", NotificationManager.IMPORTANCE_DEFAULT
        ).apply { lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE })
        phoneSleep = PhoneSleepTracking(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fitai/sleep_estimate")
            .setMethodCallHandler { call, result -> phoneSleep.handle(call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fitai/health_ui")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manageAccess" -> try {
                        startActivity(Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS))
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("UNAVAILABLE", "Open Health Connect in Settings to manage access.", null)
                    }
                    "stepTotal", "activeEnergyTotal" -> lifecycleScope.launch {
                        try {
                            val start = call.argument<Number>("start")?.toLong()
                            val end = call.argument<Number>("end")?.toLong()
                            require(start != null && end != null && end > start)
                            val client = HealthConnectClient.getOrCreate(this@MainActivity)
                            val range = TimeRangeFilter.between(Instant.ofEpochMilli(start), Instant.ofEpochMilli(end))
                            if (call.method == "stepTotal") {
                                val aggregate = client.aggregate(AggregateRequest(
                                    metrics = setOf(StepsRecord.COUNT_TOTAL), timeRangeFilter = range))
                                result.success(aggregate[StepsRecord.COUNT_TOTAL])
                            } else {
                                val aggregate = client.aggregate(AggregateRequest(
                                    metrics = setOf(ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL), timeRangeFilter = range))
                                result.success(aggregate[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]?.inKilocalories)
                            }
                        } catch (error: Exception) {
                            result.error("READ_FAILED", "This movement reading is unavailable.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (::phoneSleep.isInitialized) phoneSleep.permissionResult(requestCode)
    }
    override fun onResume() {
        super.onResume()
        hydrationTilt?.resume()
    }
    override fun onPause() {
        hydrationTilt?.pause()
        super.onPause()
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        hydrationTilt?.dispose()
        hydrationEvents?.setStreamHandler(null)
        hydrationControl?.setMethodCallHandler(null)
        hydrationTilt = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
