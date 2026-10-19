package com.example.carebridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class CareVoiceService : Service() {
    private var isPaused = false
    private var foregroundStarted = false
    private var wakePhrase = "Care"

    companion object {
        const val CHANNEL_ID = "care_voice_service_channel"
        const val NOTIFICATION_ID = 8801
        private const val WAKE_NOTIFICATION_ID = 8803
        const val ACTION_START = "com.example.carebridge.START_VOICE_SERVICE"
        const val ACTION_STOP = "com.example.carebridge.STOP_VOICE_SERVICE"
        private const val PREFS_NAME = "carebridge_voice"
        private const val PREF_WAKE_PHRASE = "wake_phrase"

        var instance: CareVoiceService? = null

        fun start(context: Context, wakePhrase: String) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(PREF_WAKE_PHRASE, wakePhrase.trim())
                .apply()
            val intent = Intent(context, CareVoiceService::class.java).apply {
                action = ACTION_START
                putExtra(PREF_WAKE_PHRASE, wakePhrase.trim())
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, CareVoiceService::class.java).apply {
                action = ACTION_STOP
            }
            context.stopService(intent)
        }

        fun pause(): Boolean {
            return instance?.pauseWakeListening() == true
        }

        fun resume(): Boolean {
            return instance?.resumeWakeListening() == true
        }

        fun currentState(): Map<String, Boolean> = mapOf(
            "running" to (instance?.foregroundStarted == true),
            "paused" to (instance?.isPaused != false)
        )
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val requestedWakePhrase = intent?.getStringExtra(PREF_WAKE_PHRASE)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getString(PREF_WAKE_PHRASE, "Care")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
            ?: "Care"
        val wakePhraseChanged = wakePhrase != requestedWakePhrase
        wakePhrase = requestedWakePhrase
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
        }

        if (intent?.action == ACTION_START && foregroundStarted) {
            if (wakePhraseChanged) {
                updateNotification("Listening for '$wakePhrase'...")
            }
            isPaused = false
            return START_NOT_STICKY
        }

        val notification = buildNotification("Listening for '$wakePhrase'...")
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (error: Exception) {
            android.util.Log.e(
                "CareVoiceService",
                "Microphone foreground service could not start",
                error
            )
            MainActivity.notifyWakeServiceError(
                "Android did not allow background microphone access. Open CareBridge and enable the assistant again."
            )
            stopSelf()
            return START_NOT_STICKY
        }
        foregroundStarted = true
        getSystemService(NotificationManager::class.java)
            ?.cancel(WAKE_NOTIFICATION_ID)

        isPaused = false
        return START_NOT_STICKY
    }

    private fun pauseWakeListening(): Boolean {
        if (!foregroundStarted) return false
        isPaused = true
        updateNotification("Wake listening paused while CareBridge handles your request")
        return true
    }

    private fun resumeWakeListening(): Boolean {
        if (!foregroundStarted) return false
        isPaused = false
        getSystemService(NotificationManager::class.java)
            ?.cancel(WAKE_NOTIFICATION_ID)
        updateNotification("Listening for '$wakePhrase'...")
        return true
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Care Voice Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Listening hands-free for '$wakePhrase'"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(statusText: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Care Voice Assistant")
            .setContentText(statusText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(createDashboardPendingIntent())
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification(statusText: String) {
        getSystemService(NotificationManager::class.java)
            ?.notify(NOTIFICATION_ID, buildNotification(statusText))
    }

    private fun createDashboardPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            9901,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
    }

    override fun onDestroy() {
        instance = null
        foregroundStarted = false
        isPaused = true
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
