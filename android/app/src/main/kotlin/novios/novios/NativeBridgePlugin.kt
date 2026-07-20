package novios.novios

import android.app.Activity
import android.app.NotificationManager
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.novios/permissions")
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        val ctx = activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        when (call.method) {
            "hasUsageStatsPermission" -> {
                result.success(checkUsageStatsPermission(ctx))
            }
            "hasNotificationAccess" -> {
                result.success(checkNotificationAccess(ctx))
            }
            "hasOverlayPermission" -> {
                result.success(checkOverlayPermission(ctx))
            }
            "hasAllPermissions" -> {
                result.success(
                    checkUsageStatsPermission(ctx) &&
                    checkNotificationAccess(ctx) &&
                    checkOverlayPermission(ctx)
                )
            }
            "openUsageStatsSettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        ctx.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    }
                } catch (_: Exception) {}
                result.success(true)
            }
            "openNotificationAccessSettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                        ctx.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    }
                } catch (_: Exception) {}
                result.success(true)
            }
            "openOverlaySettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${ctx.packageName}")
                        )
                        ctx.startActivity(intent)
                    }
                } catch (_: Exception) {}
                result.success(true)
            }
            "isBatteryOptimizationIgnored" -> {
                result.success(isIgnoringBatteryOptimizations(ctx))
            }
            "requestIgnoreBatteryOptimizations" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:${ctx.packageName}")
                        }
                        ctx.startActivity(intent)
                    }
                } catch (_: Exception) {}
                result.success(true)
            }
            "openBatterySettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        ctx.startActivity(intent)
                    }
                } catch (_: Exception) {}
                result.success(true)
            }
            "openAppSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${ctx.packageName}")
                    }
                    ctx.startActivity(intent)
                } catch (_: Exception) {}
                result.success(true)
            }
            "openXiaomiAutostart" -> {
                try {
                    val intent = Intent("miui.intent.action.OP_AUTO_START_PAGE").apply {
                        `package` = ctx.packageName
                    }
                    ctx.startActivity(intent)
                } catch (_: Exception) {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:${ctx.packageName}")
                        }
                        ctx.startActivity(intent)
                    } catch (_: Exception) {}
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkUsageStatsPermission(ctx: Activity): Boolean {
        return try {
            val usm = ctx.getSystemService(Activity.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000, now)
            stats != null && stats.isNotEmpty()
        } catch (_: Exception) {
            false
        }
    }

    private fun checkNotificationAccess(ctx: Activity): Boolean {
        return try {
            val enabled = Settings.Secure.getString(
                ctx.contentResolver,
                "enabled_notification_listeners"
            )
            enabled != null && enabled.contains(ctx.packageName)
        } catch (_: Exception) {
            false
        }
    }

    private fun checkOverlayPermission(ctx: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(ctx)
        } else true
    }

    private fun isIgnoringBatteryOptimizations(ctx: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = ctx.getSystemService(Activity.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(ctx.packageName)
        } else true
    }
}
