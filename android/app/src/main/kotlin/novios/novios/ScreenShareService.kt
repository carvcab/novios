package novios.novios

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Base64
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import java.io.ByteArrayOutputStream

class ScreenShareService : Service() {
    companion object {
        private const val CHANNEL_ID = "everus_screen_share"
        private const val NOTIFICATION_ID = 1003

        private const val MAX_WIDTH = 480
        private const val MAX_HEIGHT = 854
        private const val JPEG_QUALITY = 50

        private var mediaProjection: MediaProjection? = null
        private var virtualDisplay: VirtualDisplay? = null
        private var imageReader: ImageReader? = null
        private var isCapturing = false

        fun isActive(): Boolean = isCapturing
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var projectionManager: MediaProjectionManager
    private var wakeLock: PowerManager.WakeLock? = null
    private var firestore: FirebaseFirestore? = null
    private var uid: String? = null
    private var lastFrameHash = 0
    private var lastUploadTime = 0L
    private var width = 0
    private var height = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())

        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        uid = flutterPrefs.getString("flutter.user_uid", null)

        try {
            firestore = FirebaseFirestore.getInstance()
        } catch (e: Exception) {
            Log.e("ScreenShare", "Firestore init failed: ${e.message}")
        }

        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Novios:ScreenShareWakeLock"
            )
            wakeLock?.acquire()
        } catch (e: Exception) {
            Log.e("ScreenShare", "WakeLock failed: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null && isCapturing) return START_STICKY
        if (intent != null && intent.hasExtra("resultCode") && intent.hasExtra("data")) {
            @Suppress("DEPRECATION")
            val data = intent.getParcelableExtra("data") as? Intent
            val resultCode = intent.getIntExtra("resultCode", -1)
            if (resultCode != -1 && data != null) {
                if (!isCapturing) {
                    mediaProjection?.stop()
                    mediaProjection = projectionManager.getMediaProjection(resultCode, data)
                    markSharingActive(true)
                    startCapture()
                }
                return START_STICKY
            }
        }
        return START_STICKY
    }

    private fun markSharingActive(active: Boolean) {
        try {
            val db = firestore ?: return
            val currentUid = uid
            if (currentUid.isNullOrEmpty()) return
            db.collection("users").document(currentUid)
                .set(
                    hashMapOf<String, Any>(
                        "screenShareActive" to active,
                        "screenShareUpdatedAt" to FieldValue.serverTimestamp()
                    ),
                    com.google.firebase.firestore.SetOptions.merge()
                )
        } catch (e: Exception) {
            Log.e("ScreenShare", "markSharingActive($active) failed: ${e.message}")
        }
    }

    private fun startCapture() {
        if (isCapturing) return
        val projection = mediaProjection ?: return

        val metrics = DisplayMetrics()
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getRealMetrics(metrics)

        val density = metrics.densityDpi
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels

        val scale = minOf(MAX_WIDTH.toFloat() / screenWidth, MAX_HEIGHT.toFloat() / screenHeight, 1f)
        width = (screenWidth * scale).toInt()
        height = (screenHeight * scale).toInt()

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        virtualDisplay = projection.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )

        isCapturing = true

        imageReader?.setOnImageAvailableListener({ reader ->
            if (!isCapturing) return@setOnImageAvailableListener
            try {
                val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
                val planes = image.planes
                if (planes.isNotEmpty()) {
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * width

                    val bitmap = Bitmap.createBitmap(width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888)
                    buffer.position(0)
                    bitmap.copyPixelsFromBuffer(buffer)

                    val cropped = if (rowPadding > 0) {
                        Bitmap.createBitmap(bitmap, 0, 0, width, height)
                    } else {
                        bitmap
                    }

                    val baos = ByteArrayOutputStream()
                    cropped.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, baos)
                    val bytes = baos.toByteArray()

                    cropped.recycle()
                    bitmap.recycle()

                    val channel = MainActivity.screenShareChannel
                    if (channel != null && bytes.isNotEmpty()) {
                        handler.post {
                            try {
                                channel.invokeMethod("onFrame", bytes)
                            } catch (_: Exception) {}
                        }
                    }

                    uploadFrameToFirestore(bytes)
                }
                image.close()
            } catch (_: Exception) {}
        }, handler)

        Log.d("ScreenShare", "Screen capture started: ${width}x$height")
    }

    private fun uploadFrameToFirestore(bytes: ByteArray) {
        try {
            val currentUid = uid
            if (currentUid.isNullOrEmpty()) return

            val now = System.currentTimeMillis()
            if (now - lastUploadTime < 10000) return

            val hash = bytes.contentHashCode()
            if (hash == lastFrameHash) return
            lastFrameHash = hash

            val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
            val db = firestore ?: return

            val data = hashMapOf<String, Any>(
                "data" to b64,
                "timestamp" to FieldValue.serverTimestamp()
            )

            db.collection("screen_shares").document(currentUid)
                .collection("frames").document("latest")
                .set(data)

            db.collection("users").document(currentUid)
                .set(
                    hashMapOf<String, Any>(
                        "screenShareActive" to true,
                        "screenShareUpdatedAt" to FieldValue.serverTimestamp()
                    ),
                    com.google.firebase.firestore.SetOptions.merge()
                )

            lastUploadTime = now
        } catch (e: Exception) {
            Log.e("ScreenShare", "Firestore upload failed: ${e.message}")
        }
    }

    private fun stopCapture() {
        isCapturing = false
        try { virtualDisplay?.release() } catch (_: Exception) {}
        virtualDisplay = null
        try { imageReader?.close() } catch (_: Exception) {}
        imageReader = null
        try { mediaProjection?.stop() } catch (_: Exception) {}
        mediaProjection = null
        Log.d("ScreenShare", "Screen capture stopped")
    }

    override fun onDestroy() {
        stopCapture()
        markSharingActive(false)
        try { wakeLock?.release() } catch (_: Exception) {}
        wakeLock = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        try {
            val channel = NotificationChannel(
                CHANNEL_ID, "Compartir Pantalla",
                NotificationManager.IMPORTANCE_LOW
            )
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        } catch (_: Exception) {}
    }

    private fun createNotification(): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Novios")
            .setContentText("Compartiendo pantalla")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
    }
}
