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
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.NotificationCompat

class CareVoiceService : Service(), RecognitionListener {
    private val handler = Handler(Looper.getMainLooper())
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var isStopping = false
    private var isRecognitionPaused = false
    private var retryDelayMillis = 700L

    companion object {
        private const val CHANNEL_ID = "carebridge_voice_interaction"
        private const val NOTIFICATION_ID = 8810
        private const val ACTION_START = "com.example.carebridge.START_VOICE"
        private const val ACTION_STOP = "com.example.carebridge.STOP_VOICE"
        private const val ACTION_PAUSE = "com.example.carebridge.PAUSE_VOICE"
        private const val ACTION_RESUME = "com.example.carebridge.RESUME_VOICE"

        fun start(context: Context) {
            val intent = Intent(context, CareVoiceService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CareVoiceService::class.java))
        }

        fun pause(context: Context) {
            context.startService(
                Intent(context, CareVoiceService::class.java).apply {
                    action = ACTION_PAUSE
                }
            )
        }

        fun resume(context: Context) {
            context.startService(
                Intent(context, CareVoiceService::class.java).apply {
                    action = ACTION_RESUME
                }
            )
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action == ACTION_PAUSE) {
            isRecognitionPaused = true
            isListening = false
            handler.removeCallbacksAndMessages(null)
            speechRecognizer?.cancel()
            return START_STICKY
        }
        if (intent?.action == ACTION_RESUME) {
            isRecognitionPaused = false
            startRecognition()
            return START_STICKY
        }
        isStopping = false
        isRecognitionPaused = false
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            startRecognition()
        } catch (error: Exception) {
            android.util.Log.e("CareVoiceService", "Could not start speech recognition", error)
            MainActivity.notifyVoiceServiceError(
                error.message ?: "Android could not start background voice listening.",
                permanent = true
            )
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun startRecognition() {
        if (isStopping || isRecognitionPaused || isListening) return
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            MainActivity.notifyVoiceServiceError(
                "Install or enable an Android speech recognition service.",
                permanent = true
            )
            stopSelf()
            return
        }
        try {
            if (speechRecognizer == null) {
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).also {
                    it.setRecognitionListener(this)
                }
            }
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                )
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "en-US")
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            }
            speechRecognizer?.startListening(intent)
            isListening = true
        } catch (error: Exception) {
            isListening = false
            MainActivity.notifyVoiceServiceError(
                error.message ?: "Android speech recognition could not start."
            )
            scheduleRetry()
        }
    }

    private fun scheduleRetry(delayMillis: Long = 700L) {
        if (!isStopping) handler.postDelayed({ startRecognition() }, delayMillis)
    }

    override fun onReadyForSpeech(params: Bundle?) {
        isListening = true
    }

    override fun onBeginningOfSpeech() = Unit
    override fun onRmsChanged(rmsdB: Float) = Unit
    override fun onBufferReceived(buffer: ByteArray?) = Unit
    override fun onEndOfSpeech() = Unit

    override fun onError(error: Int) {
        isListening = false
        if (isStopping || isRecognitionPaused) return
        if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
            MainActivity.notifyVoiceServiceError(
                "Allow microphone permission to use voice listening.",
                permanent = true
            )
            stopSelf()
            return
        }
        retryDelayMillis = when (error) {
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY,
            SpeechRecognizer.ERROR_TOO_MANY_REQUESTS -> (retryDelayMillis * 2).coerceAtMost(30_000L)
            else -> 700L
        }
        scheduleRetry(retryDelayMillis)
    }

    override fun onResults(results: Bundle?) {
        isListening = false
        val transcripts = results
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            .orEmpty()
        val transcript = transcripts.firstOrNull()?.trim().orEmpty()
        if (transcript.isNotEmpty()) {
            retryDelayMillis = 700L
            MainActivity.notifyVoiceTranscript(transcript)
        }
        scheduleRetry()
    }

    override fun onPartialResults(partialResults: Bundle?) = Unit
    override fun onEvent(eventType: Int, params: Bundle?) = Unit

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        handler.post { startRecognition() }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CareBridge voice interaction",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when English voice interaction is listening."
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            8810,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CareBridge voice assistant")
            .setContentText(
                "Listening for care updates; voice SOS works only while the app is open."
            )
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        isStopping = true
        isListening = false
        handler.removeCallbacksAndMessages(null)
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
