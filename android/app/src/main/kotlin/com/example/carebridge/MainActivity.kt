package com.example.carebridge

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "carebridge/emergency_call"
    private val systemChannelName = "carebridge/system"
    private val voiceChannelName = "carebridge/voice_background"
    private val emergencyLocationChannelName = "carebridge/emergency_location"
    private val reminderAnnouncementChannelName = "carebridge/reminder_announcements"
    private val callPermissionRequestCode = 9101
    private var pendingPhoneNumber: String? = null
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private var emergencyLocationMethodChannel: MethodChannel? = null
        private var voiceMethodChannel: MethodChannel? = null

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

        fun notifyVoiceTranscript(transcript: String) {
            Handler(Looper.getMainLooper()).post {
                voiceMethodChannel?.invokeMethod("onVoiceTranscript", transcript)
            }
        }

        fun notifyVoiceServiceError(message: String, permanent: Boolean = false) {
            Handler(Looper.getMainLooper()).post {
                voiceMethodChannel?.invokeMethod(
                    "onVoiceServiceError",
                    mapOf("message" to message, "permanent" to permanent)
                )
            }
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

        val voiceChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            voiceChannelName
        )
        voiceMethodChannel = voiceChannel
        voiceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVoiceListening" -> {
                    try {
                        CareVoiceService.start(this)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("VOICE_SERVICE_START_FAILED", error.message, null)
                    }
                }
                "stopVoiceListening" -> {
                    try {
                        CareVoiceService.stop(this)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("VOICE_SERVICE_STOP_FAILED", error.message, null)
                    }
                }
                "pauseVoiceListening" -> {
                    try {
                        CareVoiceService.pause(this)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("VOICE_SERVICE_PAUSE_FAILED", error.message, null)
                    }
                }
                "resumeVoiceListening" -> {
                    try {
                        CareVoiceService.resume(this)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("VOICE_SERVICE_RESUME_FAILED", error.message, null)
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            reminderAnnouncementChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRecentReminder" -> result.success(
                    ReminderAlarmReceiver.getRecentReminder(this)
                )
                "clearRecentReminder" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error(
                            "INVALID_REMINDER_ID",
                            "A reminder ID is required.",
                            null
                        )
                    } else {
                        result.success(
                            ReminderAlarmReceiver.clearRecentReminder(this, id)
                        )
                    }
                }
                "syncReminderAlarms" -> {
                    val reminders = call.argument<List<Map<String, Any?>>>("reminders")
                    if (reminders == null) {
                        result.error(
                            "INVALID_REMINDER_SCHEDULE",
                            "A reminder schedule is required.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    try {
                        ReminderAlarmReceiver.replace(this, reminders)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error(
                            "REMINDER_ALARM_SYNC_FAILED",
                            error.message ?: "Could not update spoken reminder alarms.",
                            null
                        )
                    }
                }
                else -> result.notImplemented()
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

}
