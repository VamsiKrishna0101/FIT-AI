package com.example.fitai_mobile

import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
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
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val notifications = getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(NotificationChannel(
            "fitai_reminders", "FitAI reminders", NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Workout reminders, check-ins and plan updates"
            lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
        })
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
}
