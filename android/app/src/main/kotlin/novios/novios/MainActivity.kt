package novios.novios

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.novios/app"
        private const val REQUEST_SCREEN_CAPTURE = 1001

        @JvmStatic var appTrackerChannel: MethodChannel? = null
        @JvmStatic var notificationChannel: MethodChannel? = null
        @JvmStatic var screenShareChannel: MethodChannel? = null

        private var pendingScreenShareResult: MethodChannel.Result? = null
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        appTrackerChannel = MethodChannel(messenger, "com.novios/app_tracker")
        notificationChannel = MethodChannel(messenger, "com.novios/notifications")
        screenShareChannel = MethodChannel(messenger, "com.novios/screen_share")

        flutterEngine.plugins.add(NativeBridgePlugin())

        appTrackerChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTracking" -> {
                    try {
                        startService(Intent(this, CurrentAppService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "stopTracking" -> {
                    try {
                        stopService(Intent(this, CurrentAppService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getCurrentApp" -> {
                    try {
                        val usm = getSystemService(android.content.Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
                        val now = System.currentTimeMillis()
                        val stats = usm.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, now - 10000, now)
                        if (stats != null) {
                            val sorted = stats.filter { it.lastTimeUsed > 0 }.sortedByDescending { it.lastTimeUsed }
                            result.success(sorted.firstOrNull()?.packageName ?: "")
                        } else {
                            result.success("")
                        }
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                else -> result.notImplemented()
            }
        }

        screenShareChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreenShare" -> {
                    if (pendingScreenShareResult != null) {
                        result.success("busy")
                        return@setMethodCallHandler
                    }
                    pendingScreenShareResult = result
                    try {
                        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(mgr.createScreenCaptureIntent(), REQUEST_SCREEN_CAPTURE)
                    } catch (e: Exception) {
                        pendingScreenShareResult?.success("error: ${e.message}")
                        pendingScreenShareResult = null
                    }
                }
                "stopScreenShare" -> {
                    try {
                        stopService(Intent(this, ScreenShareService::class.java))
                    } catch (_: Exception) {}
                    result.success(true)
                }
                "isScreenSharing" -> {
                    result.success(ScreenShareService.isActive())
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCurrentAppService" -> {
                    try {
                        startService(Intent(this, CurrentAppService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "startScreenShareService" -> {
                    val code = call.argument<Int>("code") ?: -1
                    try {
                        val intent = Intent(this, ScreenShareService::class.java)
                        intent.putExtra("code", code)
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "restartScreenShare" -> {
                    if (ScreenShareService.isActive()) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    try {
                        startService(Intent(this, ScreenShareService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "stopScreenShareService" -> {
                    try {
                        stopService(Intent(this, ScreenShareService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_SCREEN_CAPTURE) {
            val pending = pendingScreenShareResult
            pendingScreenShareResult = null

            if (resultCode == Activity.RESULT_OK && data != null) {
                try {
                    val intent = Intent(this, ScreenShareService::class.java).apply {
                        putExtra("resultCode", resultCode)
                        putExtra("data", data)
                    }
                    startService(intent)
                    pending?.success("granted")
                } catch (e: Exception) {
                    pending?.success("error: ${e.message}")
                }
            } else {
                pending?.success("denied")
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Thread.setDefaultUncaughtExceptionHandler { _, e ->
            try {
                val sp = getSharedPreferences("flutter_errors", MODE_PRIVATE)
                sp.edit().putString("last_native_error", "${e.message}\n${e.stackTraceToString()}").apply()
            } catch (_: Exception) {}
        }
    }
}
