package com.setcraft.app

import android.content.ClipData
import android.content.Intent
import android.os.Build
import androidx.core.content.FileProvider
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import org.json.JSONObject

internal class AccountSettingsBridge(private val activity: FlutterFragmentActivity, messenger: BinaryMessenger) {
    private val directory get() = File(activity.cacheDir, "account_exports")
    private fun clear() { directory.listFiles()?.filter { it.isFile }?.forEach { it.delete() } }
    init {
        clear()
        MethodChannel(messenger, "setcraft/settings").setMethodCallHandler { call, result ->
            when(call.method) {
                "appInfo" -> {
                    val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
                    val build = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                    result.success(mapOf("appVersion" to (info.versionName ?: ""), "buildNumber" to build.toString(), "platform" to "android", "osVersion" to Build.VERSION.RELEASE))
                }
                "clearExports" -> { clear(); result.success(null) }
                "shareExport" -> {
                    val json = call.argument<String>("json")
                    if (json == null || json.length > 50 * 1024 * 1024) {
                        result.error("INVALID_EXPORT", "This export could not be prepared.", null)
                    } else activity.lifecycleScope.launch {
                        try {
                            val file = withContext(Dispatchers.IO) {
                                JSONObject(json)
                                clear(); directory.mkdirs()
                                File.createTempFile("setcraft-data-", ".json", directory).also { it.writeText(json, Charsets.UTF_8) }
                            }
                            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.account_exports", file)
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "application/json"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("Setcraft data export", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            activity.startActivity(Intent.createChooser(intent, "Export Setcraft data"))
                            result.success(null)
                        } catch (_: Exception) {
                            clear(); result.error("EXPORT_FAILED", "Could not open the share sheet. Please try again.", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
