package com.example.carebridge

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class EmergencyLocationService : Service(), LocationListener {
    private var locationManager: LocationManager? = null
    private var elderId: String? = null
    private var emergencyId: String? = null

    companion object {
        private const val CHANNEL_ID = "carebridge_emergency_location"
        private const val NOTIFICATION_ID = 8802
        private const val ACTION_START =
            "com.example.carebridge.START_EMERGENCY_LOCATION"
        private const val ACTION_STOP =
            "com.example.carebridge.STOP_EMERGENCY_LOCATION"

        fun start(context: Context, elderId: String, emergencyId: String) {
            val intent = Intent(context, EmergencyLocationService::class.java).apply {
                action = ACTION_START
                putExtra("elderId", elderId)
                putExtra("emergencyId", emergencyId)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(
                Intent(context, EmergencyLocationService::class.java).apply {
                    action = ACTION_STOP
                }
            )
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopTracking()
            stopSelf()
            return START_NOT_STICKY
        }

        elderId = intent?.getStringExtra("elderId")
        emergencyId = intent?.getStringExtra("emergencyId")
        createNotificationChannel()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        requestLocationUpdates()
        return START_NOT_STICKY
    }

    private fun requestLocationUpdates() {
        val fineGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (!fineGranted && !coarseGranted) {
            MainActivity.notifyEmergencyLocationError(
                "Location permission is required to share the live emergency location."
            )
            stopSelf()
            return
        }

        try {
            locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER
            ).filter { provider -> locationManager?.isProviderEnabled(provider) == true }
            if (providers.isEmpty()) {
                MainActivity.notifyEmergencyLocationError(
                    "Turn on Location to share live emergency updates."
                )
                stopSelf()
                return
            }
            providers.forEach { provider ->
                locationManager?.requestLocationUpdates(provider, 5000L, 5f, this)
            }
        } catch (error: SecurityException) {
            MainActivity.notifyEmergencyLocationError(
                error.message ?: "Location permission was denied."
            )
            stopSelf()
        } catch (error: IllegalArgumentException) {
            MainActivity.notifyEmergencyLocationError(
                error.message ?: "No location provider is available."
            )
            stopSelf()
        }
    }

    override fun onLocationChanged(location: Location) {
        val activeElderId = elderId ?: return
        val activeEmergencyId = emergencyId ?: return
        MainActivity.notifyEmergencyLocation(
            activeElderId,
            activeEmergencyId,
            location.latitude,
            location.longitude
        )
    }

    @Deprecated("Deprecated by Android")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit

    override fun onProviderEnabled(provider: String) = Unit

    override fun onProviderDisabled(provider: String) {
        MainActivity.notifyEmergencyLocationError(
            "Location provider $provider was turned off."
        )
    }

    private fun stopTracking() {
        locationManager?.removeUpdates(this)
        locationManager = null
        stopForeground(true)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Emergency live location",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shown while CareBridge shares emergency location updates."
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Emergency location sharing")
            .setContentText("Sharing your current location with your CareBridge family")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
