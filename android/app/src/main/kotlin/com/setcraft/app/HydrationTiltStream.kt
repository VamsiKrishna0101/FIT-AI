package com.setcraft.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs

/** Foreground-only gravity samples for the local water illustration. */
class HydrationTiltStream(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val manager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    private val sensor = manager?.getDefaultSensor(Sensor.TYPE_GRAVITY)
        ?: manager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    val available: Boolean get() = sensor != null
    private var sink: EventChannel.EventSink? = null
    private var foreground = true
    private var registered = false
    private var filtered = floatArrayOf(0f, 0f, 0f)
    private var first = true
    private var sentAt = 0L
    private var lastX = Double.NaN
    private var lastY = Double.NaN
    private var lastZ = Double.NaN

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        first = true
        sentAt = 0L
        lastX = Double.NaN
        lastY = Double.NaN
        lastZ = Double.NaN
        start()
    }
    override fun onCancel(arguments: Any?) {
        stop()
        sink = null
    }
    private fun start() {
        if (!registered && foreground && sink != null && sensor != null) {
            registered = manager?.registerListener(this, sensor, 33_333) == true
        }
    }
    private fun stop() {
        manager?.unregisterListener(this)
        registered = false
    }
    fun resume() { foreground = true; start() }
    fun pause() { foreground = false; stop() }
    fun dispose() { stop(); sink = null }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    override fun onSensorChanged(event: SensorEvent) {
        if (!foreground || sink == null) return
        val alpha = if (event.sensor.type == Sensor.TYPE_GRAVITY || first) 1f else .16f
        for (i in 0..2) filtered[i] += alpha * (event.values[i] - filtered[i])
        first = false
        if (event.timestamp - sentAt < 33_000_000L) return
        // Android's acceleration includes the support force; use physical gravity,
        // matching Core Motion's device-coordinate convention on iOS.
        val x = -filtered[0].toDouble() / SensorManager.STANDARD_GRAVITY
        val y = -filtered[1].toDouble() / SensorManager.STANDARD_GRAVITY
        val z = -filtered[2].toDouble() / SensorManager.STANDARD_GRAVITY
        if (!x.isFinite() || !y.isFinite() || !z.isFinite()) return
        if (lastX.isFinite() && abs(x - lastX) + abs(y - lastY) + abs(z - lastZ) < .003) return
        lastX = x; lastY = y; lastZ = z; sentAt = event.timestamp
        sink?.success(listOf(x, y, z))
    }
}
