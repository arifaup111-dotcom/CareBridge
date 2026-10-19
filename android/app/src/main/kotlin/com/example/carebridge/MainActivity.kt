package com.example.carebridge

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.telephony.SmsManager
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "carebridge/emergency_call"
    private val systemChannelName = "carebridge/system"
    private val voiceChannelName = "carebridge/voice_background"
    private val emergencyLocationChannelName = "carebridge/emergency_location"
    private val callPermissionRequestCode = 9101
    private var pendingPhoneNumber: String? = null
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private var voiceMethodChannel: MethodChannel? = null
        private var emergencyLocationMethodChannel: MethodChannel? = null
        private var pendingWakePhrase: String? = null
        private var wakeListenerReady = false

        fun notifyWakeWordDetected(phrase: String) {
            Handler(Looper.getMainLooper()).post {
                if (wakeListenerReady && voiceMethodChannel != null) {
                    voiceMethodChannel?.invokeMethod("onWakeWordDetected", mapOf("wakePhrase" to phrase))
                } else {
                    pendingWakePhrase = phrase
                }
            }
        }

        fun notifyWakeServiceError(message: String) {
            Handler(Looper.getMainLooper()).post {
                voiceMethodChannel?.invokeMethod("onWakeServiceError", message)
            }
        }

        fun notifyEmergencyLocation(
            elderId: String,
            emergencyId: String,
            latitude: Double,
            longitude: Double
        ) {
            Handler(Looper.getMainLooper()).post {
                emergencyLocationMethodChannel?.invokeMethod(
                    "onEmergencyLocationUpdate",
                    mapOf(
                        "elderId" to elderId,
                        "emergencyId" to emergencyId,
                        "latitude" to latitude,
                        "longitude" to longitude
                    )
                )
            }
        }

        fun notifyEmergencyLocationError(message: String) {
            Handler(Looper.getMainLooper()).post {
                emergencyLocationMethodChannel?.invokeMethod(
                    "onEmergencyLocationError",
                    message
                )
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wakeUpScreen()
        handleWakeIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeUpScreen()
        handleWakeIntent(intent)
    }

    private fun handleWakeIntent(intent: Intent?) {
        if (intent == null) return
        val triggered = intent.getBooleanExtra("wake_word_triggered", false)
        val phrase = intent.getStringExtra("wake_phrase") ?: "Care"
        if (triggered) {
            notifyWakeWordDetected(phrase)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendEmergencyLocationSms" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")?.trim()
                        val latitude = call.argument<Double>("latitude")
                        val longitude = call.argument<Double>("longitude")
                        if (phoneNumber.isNullOrEmpty() ||
                            latitude == null ||
                            longitude == null
                        ) {
                            result.error(
                                "INVALID_EMERGENCY_SMS",
                                "A phone number and location are required.",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        if (ActivityCompat.checkSelfPermission(
                                this,
                                Manifest.permission.SEND_SMS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error(
                                "SMS_PERMISSION_DENIED",
                                "SMS permission is required to send the emergency location.",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        try {
                            val message =
                                "Emergency! I need help. My current location: " +
                                    "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude"
                            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                getSystemService(SmsManager::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getDefault()
                            }
                            val parts = smsManager.divideMessage(message)
                            if (parts.size == 1) {
                                smsManager.sendTextMessage(
                                    phoneNumber,
                                    null,
                                    message,
                                    null,
                                    null
                                )
                            } else {
                                smsManager.sendMultipartTextMessage(
                                    phoneNumber,
                                    null,
                                    parts,
                                    null,
                                    null
                                )
                            }
                            result.success(true)
                        } catch (error: Exception) {
                            result.error(
                                "SMS_SEND_FAILED",
                                error.message ?: "The emergency SMS could not be queued.",
                                null
                            )
                        }
                    }
                    "directCall" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")?.trim()
                        if (phoneNumber.isNullOrEmpty()) {
                            result.error("INVALID_NUMBER", "Emergency phone number is empty", null)
                            return@setMethodCallHandler
                        }

                        if (ActivityCompat.checkSelfPermission(
                                this,
                                Manifest.permission.CALL_PHONE
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            pendingPhoneNumber = phoneNumber
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.CALL_PHONE),
                                callPermissionRequestCode
                            )
                            return@setMethodCallHandler
                        }

                        placeDirectCall(phoneNumber, result)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "localTimeZone" -> result.success(java.util.TimeZone.getDefault().id)
                    else -> result.notImplemented()
                }
            }

        val voiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, voiceChannelName)
        voiceMethodChannel = voiceChannel
        wakeListenerReady = false
        voiceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "registerWakeWordListener" -> {
                    wakeListenerReady = true
                    pendingWakePhrase?.let { phrase ->
                        pendingWakePhrase = null
                        voiceMethodChannel?.invokeMethod(
                            "onWakeWordDetected",
                            mapOf("wakePhrase" to phrase)
                        )
                    }
                    result.success(true)
                }
                "startForegroundVoice" -> {
                    try {
                        val wakePhrase = call.argument<String>("wakePhrase")?.trim()
                        if (wakePhrase.isNullOrEmpty()) {
                            result.error(
                                "INVALID_WAKE_PHRASE",
                                "A wake name is required.",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        CareVoiceService.start(this, wakePhrase)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_FAILED", e.message, null)
                    }
                }
                "stopForegroundVoice" -> {
                    try {
                        CareVoiceService.stop(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_FAILED", e.message, null)
                    }
                }
                "pauseForegroundVoice" -> {
                    try {
                        if (CareVoiceService.pause()) {
                            result.success(true)
                        } else {
                            result.error("VOICE_SERVICE_NOT_RUNNING", "Wake listening is not active.", null)
                        }
                    } catch (e: Exception) {
                        result.error("PAUSE_FAILED", e.message, null)
                    }
                }
                "resumeForegroundVoice" -> {
                    try {
                        if (CareVoiceService.resume()) {
                            result.success(true)
                        } else {
                            result.error("VOICE_SERVICE_NOT_RUNNING", "Wake listening could not resume.", null)
                        }
                    } catch (e: Exception) {
                        result.error("RESUME_FAILED", e.message, null)
                    }
                }
                "getForegroundVoiceState" -> {
                    result.success(CareVoiceService.currentState())
                }
                "wakeScreen" -> {
                    try {
                        wakeUpScreen()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val emergencyLocationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            emergencyLocationChannelName
        )
        emergencyLocationMethodChannel = emergencyLocationChannel
        emergencyLocationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startEmergencyLocation" -> {
                    val elderId = call.argument<String>("elderId")?.trim()
                    val emergencyId = call.argument<String>("emergencyId")?.trim()
                    if (elderId.isNullOrEmpty() || emergencyId.isNullOrEmpty()) {
                        result.error(
                            "INVALID_EMERGENCY",
                            "Emergency location requires an Elder and alert ID.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    try {
                        EmergencyLocationService.start(this, elderId, emergencyId)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCATION_SERVICE_START_FAILED", e.message, null)
                    }
                }
                "stopEmergencyLocation" -> {
                    try {
                        EmergencyLocationService.stop(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCATION_SERVICE_STOP_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

    }

    private fun wakeUpScreen() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                )
            }
            try {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                @Suppress("DEPRECATION")
                val screenWakeLock = powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "CareBridge::ScreenWakeLock"
                )
                screenWakeLock.acquire(5000L)
            } catch (e: Exception) {
                // Ignore wake lock exceptions if system restrictions apply
            }
        }
    }

    private fun placeDirectCall(phoneNumber: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:${Uri.encode(phoneNumber)}")
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("CALL_FAILED", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != callPermissionRequestCode) return

        val number = pendingPhoneNumber
        val result = pendingResult
        pendingPhoneNumber = null
        pendingResult = null

        if (number == null || result == null) return

        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            placeDirectCall(number, result)
        } else {
            result.error("PERMISSION_DENIED", "Phone call permission was denied", null)
        }
    }

    override fun onDestroy() {
        voiceMethodChannel = null
        super.onDestroy()
    }
}
