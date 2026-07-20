package com.novios

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import org.json.JSONObject

class CurrentAppService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var currentApp = ""
    private var firestore: FirebaseFirestore? = null
    private var uid: String? = null
    private var screenReceiver: BroadcastReceiver? = null
    private var lastAppLabel = ""

    companion object {
        private const val CHANNEL_ID = "everus_current_app"
        private const val NOTIFICATION_ID = 1002
        private const val POLL_INTERVAL_MS = 3000L
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        try {
            val notification = Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Novios")
                .setContentText("Monitoreo activo")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .build()
            startForeground(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            stopSelf()
            return
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        uid = prefs.getString("flutter.user_uid", null)

        if (uid.isNullOrEmpty()) {
            Log.w("AppTracker", "No UID found, service will retry")
        }

        try {
            firestore = FirebaseFirestore.getInstance()
        } catch (e: Exception) {
            Log.e("AppTracker", "Firestore init failed: ${e.message}")
        }

        registerScreenReceiver()
        listenForPartnerNotifications()
    }

    private fun registerScreenReceiver() {
        try {
            screenReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    when (intent?.action) {
                        Intent.ACTION_SCREEN_OFF -> {
                            Log.d("AppTracker", "Screen OFF")
                            updateFirestore("", "", "suspendido")
                        }
                        Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                            Log.d("AppTracker", "Screen ON")
                            updateFirestore(currentApp, lastAppLabel, "activo")
                        }
                    }
                }
            }
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            registerReceiver(screenReceiver, filter)
        } catch (e: Exception) {
            Log.e("AppTracker", "Screen receiver failed: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (uid.isNullOrEmpty()) {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            uid = prefs.getString("flutter.user_uid", null)
        }
        handler.post(checkAppRunnable)
        return START_STICKY
    }

    private val checkAppRunnable = object : Runnable {
        override fun run() {
            try {
                if (uid.isNullOrEmpty()) {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    uid = prefs.getString("flutter.user_uid", null)
                }

                val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
                val now = System.currentTimeMillis()
                var detectedPkg = ""

                try {
                    val events = usm.queryEvents(now - 15000, now)
                    if (events != null) {
                        val event = android.app.usage.UsageEvents.Event()
                        while (events.hasNextEvent()) {
                            events.getNextEvent(event)
                            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND || event.eventType == 1) {
                                detectedPkg = event.packageName
                            }
                        }
                    }
                } catch (_: Exception) {}

                if (detectedPkg.isEmpty()) {
                    val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 10000, now)
                    if (stats != null) {
                        val sorted = stats.filter { it.lastTimeUsed > 0 && it.packageName != "android" }.sortedByDescending { it.lastTimeUsed }
                        detectedPkg = sorted.firstOrNull()?.packageName ?: ""
                    }
                }

                if (detectedPkg.isNotEmpty() && detectedPkg != "android") {
                    val pkg = detectedPkg
                    if (pkg != currentApp) {
                        currentApp = pkg
                        try {
                            val pm = packageManager
                            lastAppLabel = pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
                        } catch (e: Exception) {
                            lastAppLabel = pkg
                        }

                        val json = JSONObject().apply {
                            put("app", pkg)
                            put("label", lastAppLabel)
                        }

                        val channel = MainActivity.appTrackerChannel
                        channel?.invokeMethod("onAppChange", json.toString())
                    }

                    if (currentApp.isNotEmpty()) {
                        updateFirestore(currentApp, lastAppLabel, null)
                    }
                }
            } catch (e: Exception) {
                Log.e("AppTracker", "Poll error: ${e.message}")
            }
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    private fun updateFirestore(app: String, label: String, st: String?) {
        try {
            val db = firestore ?: return
            val currentUid = uid
            if (currentUid.isNullOrEmpty()) return

            val data = hashMapOf<String, Any>()
            if (st != null) {
                data["phoneState"] = st
            }
            if (app.isNotEmpty()) {
                data["currentApp"] = app
                data["currentAppLabel"] = label
                data["lastAppUpdate"] = com.google.firebase.firestore.FieldValue.serverTimestamp()
            }
            if (data.isEmpty()) return

            db.collection("users").document(currentUid)
                .set(data, com.google.firebase.firestore.SetOptions.merge())

            Log.d("AppTracker", "Firestore: app=$app label=$label state=$st")
        } catch (e: Exception) {
            Log.e("AppTracker", "Firestore write failed: ${e.message}")
        }
    }

    private var partnerMsgListener: com.google.firebase.firestore.ListenerRegistration? = null
    private var lastNotifSeenTime: Long = 0

    private fun listenForPartnerNotifications() {
        try {
            val db = firestore ?: return
            val currentUid = uid
            if (currentUid.isNullOrEmpty()) return

            partnerMsgListener?.remove()

            partnerMsgListener = db.collection("users").document(currentUid)
                .addSnapshotListener { snap, err ->
                    if (err != null || snap == null || !snap.exists()) return@addSnapshotListener
                    
                    @Suppress("UNCHECKED_CAST")
                    val lastNotif = snap.get("lastNotification") as? Map<String, Any> ?: return@addSnapshotListener
                    val lastTime = snap.getTimestamp("lastNotificationTime") ?: return@addSnapshotListener
                    
                    val timeMs = lastTime.toDate().time
                    if (lastNotifSeenTime == 0L) {
                        lastNotifSeenTime = timeMs
                        return@addSnapshotListener
                    }
                    if (timeMs <= lastNotifSeenTime) return@addSnapshotListener
                    lastNotifSeenTime = timeMs

                    val app = lastNotif["app"] as? String ?: "EverUs"
                    val title = lastNotif["title"] as? String ?: "Tu pareja"
                    val text = lastNotif["text"] as? String ?: ""

                    showNativeHeadsUpNotification(title, text)
                }
        } catch (e: Exception) {
            Log.e("AppTracker", "Partner notification listener failed: ${e.message}")
        }
    }

    private fun showNativeHeadsUpNotification(title: String, text: String) {
        try {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            
            val channel = NotificationChannel(
                "partner_chat_heads_up",
                "Mensajes de Pareja",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones de mensajes y juegos de tu pareja"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
            }
            nm.createNotificationChannel(channel)

            val intent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                this, 0, intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )

            val builder = Notification.Builder(this, "partner_chat_heads_up")
                .setContentTitle("💞 $title")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(Notification.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            nm.notify((System.currentTimeMillis() % 100000).toInt(), builder.build())
        } catch (e: Exception) {
            Log.e("AppTracker", "Heads up notification failed: ${e.message}")
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkAppRunnable)
        try { partnerMsgListener?.remove() } catch (_: Exception) {}
        try { screenReceiver?.let { unregisterReceiver(it) } } catch (_: Exception) {}
        screenReceiver = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        try {
            val channel = NotificationChannel(
                CHANNEL_ID, "App Activa",
                NotificationManager.IMPORTANCE_LOW
            )
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        } catch (_: Exception) {}
    }
}

