package com.example.carebridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.app.NotificationCompat
import java.util.ArrayDeque
import java.util.Locale

class ReminderAnnouncementService : Service(), TextToSpeech.OnInitListener {
    companion object {
        const val ACTION_ANNOUNCE = "com.example.carebridge.ANNOUNCE_REMINDER"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        private const val CHANNEL_ID = "carebridge_reminder_speech"
        private const val NOTIFICATION_ID = 8815
    }

    private val announcements = ArrayDeque<String>()
    private var textToSpeech: TextToSpeech? = null
    private var languageReady = false
    private var speaking = false
    private var utteranceIndex = 0
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        textToSpeech = TextToSpeech(this, this)
        textToSpeech?.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) {
                    android.os.Handler(mainLooper).post {
                        speaking = false
                        speakNext()
                    }
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    android.os.Handler(mainLooper).post {
                        speaking = false
                        speakNext()
                    }
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    android.util.Log.w(
                        "ReminderAnnouncement",
                        "Text-to-speech announcement failed with code $errorCode."
                    )
                    android.os.Handler(mainLooper).post {
                        speaking = false
                        speakNext()
                    }
                }
            }
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action != ACTION_ANNOUNCE) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        val text = intent.getStringExtra(EXTRA_TEXT)?.trim().orEmpty()
        if (text.isEmpty()) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        announcements.addLast(text)
        startInForeground()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "CareBridge:ReminderSpeech")
            .apply { acquire(120_000L) }
        speakNext()
        return START_NOT_STICKY
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) {
            android.util.Log.w("ReminderAnnouncement", "Text-to-speech engine failed to initialize.")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        val result = textToSpeech?.setLanguage(Locale("ml", "IN"))
        languageReady = result != null &&
            result != TextToSpeech.LANG_MISSING_DATA &&
            result != TextToSpeech.LANG_NOT_SUPPORTED
        if (!languageReady) {
            android.util.Log.w("ReminderAnnouncement", "Malayalam speech is unavailable; the scheduled notification remains available.")
            announcements.clear()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        textToSpeech?.setSpeechRate(0.9f)
        speakNext()
    }

    private fun speakNext() {
        if (!languageReady || speaking) return
        val next = announcements.pollFirst()
        if (next == null) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        speaking = true
        val result = textToSpeech?.speak(
            next,
            TextToSpeech.QUEUE_FLUSH,
            Bundle(),
            "care-reminder-${++utteranceIndex}"
        ) ?: TextToSpeech.ERROR
        if (result == TextToSpeech.ERROR) {
            speaking = false
            android.util.Log.w("ReminderAnnouncement", "Malayalam announcement could not be queued.")
            speakNext()
        }
    }

    private fun startInForeground() {
        val openApp = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CareBridge reminder")
            .setContentText("ഒരു പരിചരണ ഓർമ്മപ്പെടുത്തൽ വായിക്കുന്നു.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openApp)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CareBridge spoken reminders",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Temporary notification shown while a reminder is spoken."
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
