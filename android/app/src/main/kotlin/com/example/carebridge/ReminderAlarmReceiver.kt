package com.example.carebridge

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class ReminderAlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val PREFS = "carebridge_reminder_alarms"
        private const val REMINDERS_KEY = "reminders"
        private const val LAST_TRIGGERED_KEY = "last_triggered_reminder"
        private const val ACTION_REMINDER = "com.example.carebridge.CARE_REMINDER"
        private const val REMINDER_CONTEXT_MAX_AGE_MILLIS = 4 * 60 * 60 * 1000L

        fun getRecentReminder(context: Context): Map<String, Any?>? {
            val json = runCatching {
                JSONObject(
                    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                        .getString(LAST_TRIGGERED_KEY, "{}")
                )
            }.getOrNull() ?: return null
            val triggeredAt = json.optLong("triggeredAt", 0L)
            if (triggeredAt <= 0L ||
                System.currentTimeMillis() - triggeredAt > REMINDER_CONTEXT_MAX_AGE_MILLIS
            ) {
                return null
            }
            return mapOf(
                "id" to json.optInt("id"),
                "type" to json.optString("type"),
                "key" to json.optString("key"),
                "triggeredAt" to triggeredAt
            )
        }

        fun clearRecentReminder(context: Context, id: Int): Boolean {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val current = runCatching {
                JSONObject(prefs.getString(LAST_TRIGGERED_KEY, "{}"))
            }.getOrNull() ?: return false
            if (current.optInt("id") != id) return false
            return prefs.edit().remove(LAST_TRIGGERED_KEY).commit()
        }

        fun replace(context: Context, reminders: List<Map<String, Any?>>) {
            createNotificationChannels(context)
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val previous = runCatching {
                JSONArray(prefs.getString(REMINDERS_KEY, "[]"))
            }.getOrDefault(JSONArray())
            for (index in 0 until previous.length()) {
                previous.optJSONObject(index)?.let { cancel(context, it.optInt("id")) }
            }

            val updated = JSONArray()
            for (reminder in reminders) {
                val id = (reminder["id"] as? Number)?.toInt() ?: continue
                val json = JSONObject().apply {
                    put("id", id)
                    put("type", reminder["type"]?.toString().orEmpty())
                    put("key", reminder["key"]?.toString().orEmpty())
                    put("title", reminder["title"]?.toString().orEmpty())
                    put("body", reminder["body"]?.toString().orEmpty())
                    put("year", (reminder["year"] as? Number)?.toInt() ?: 0)
                    put("month", (reminder["month"] as? Number)?.toInt() ?: 0)
                    put("day", (reminder["day"] as? Number)?.toInt() ?: 0)
                    put("hour", (reminder["hour"] as? Number)?.toInt() ?: 0)
                    put("minute", (reminder["minute"] as? Number)?.toInt() ?: 0)
                    put("daily", reminder["daily"] == true)
                }
                updated.put(json)
            }
            check(prefs.edit().putString(REMINDERS_KEY, updated.toString()).commit()) {
                "Could not persist the reminder schedule."
            }
            scheduleAll(context, updated)
        }

        private fun cancel(context: Context, id: Int) {
            if (id == 0) return
            val alarmManager = context.getSystemService(AlarmManager::class.java)
            alarmManager.cancel(pendingIntent(context, id))
        }

        private fun pendingIntent(context: Context, id: Int): PendingIntent {
            val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
                action = ACTION_REMINDER
                data = android.net.Uri.parse("carebridge://reminder/$id")
            }
            return PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun scheduleAll(context: Context, reminders: JSONArray) {
            for (index in 0 until reminders.length()) {
                reminders.optJSONObject(index)?.let { schedule(context, it) }
            }
        }

        private fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            for (type in listOf("meal", "water", "wake_up", "exercise", "medicine", "appointment")) {
                val channel = NotificationChannel(
                    "care_$type",
                    channelName(type),
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Scheduled Malayalam care reminders."
                    enableVibration(true)
                    setSound(null, null)
                }
                manager.createNotificationChannel(channel)
            }
        }

        private fun channelName(type: String): String = when (type) {
            "meal" -> "Meal Reminders"
            "water" -> "Water Reminders"
            "wake_up" -> "Wake-up Reminders"
            "exercise" -> "Exercise Reminders"
            "medicine" -> "Medicine Reminders"
            "appointment" -> "Appointment Reminders"
            else -> "Care Reminders"
        }

        private fun schedule(context: Context, reminder: JSONObject) {
            val id = reminder.optInt("id")
            if (id == 0) return
            val triggerAt = nextTrigger(reminder) ?: return
            val alarmManager = context.getSystemService(AlarmManager::class.java)
            val intent = pendingIntent(context, id)
            try {
                if (
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                    alarmManager.canScheduleExactAlarms()
                ) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        intent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        intent
                    )
                }
            } catch (error: SecurityException) {
                android.util.Log.w(
                    "ReminderAlarmReceiver",
                    "Exact alarm access was denied; scheduling an inexact reminder.",
                    error
                )
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    intent
                )
            }
        }

        private fun nextTrigger(reminder: JSONObject): Long? {
            val year = reminder.optInt("year")
            val month = reminder.optInt("month")
            val day = reminder.optInt("day")
            val hour = reminder.optInt("hour")
            val minute = reminder.optInt("minute")
            if (year < 1 || month !in 1..12 || day !in 1..31 ||
                hour !in 0..23 || minute !in 0..59
            ) {
                return null
            }
            val daily = reminder.optBoolean("daily")
            val trigger = Calendar.getInstance().apply {
                if (!daily) {
                    set(Calendar.YEAR, year)
                    set(Calendar.MONTH, month - 1)
                    set(Calendar.DAY_OF_MONTH, day)
                }
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (daily && trigger.timeInMillis <= System.currentTimeMillis()) {
                trigger.add(Calendar.DAY_OF_MONTH, 1)
            }
            return trigger.timeInMillis.takeIf {
                daily || it > System.currentTimeMillis()
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        if (intent.action != ACTION_REMINDER) {
            val reminders = runCatching {
                JSONArray(
                    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                        .getString(REMINDERS_KEY, "[]")
                )
            }.getOrDefault(JSONArray())
            scheduleAll(context, reminders)
            return
        }

        val id = intent.data?.lastPathSegment?.toIntOrNull() ?: return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val reminders = runCatching {
            JSONArray(prefs.getString(REMINDERS_KEY, "[]"))
        }.getOrDefault(JSONArray())
        val matching = (0 until reminders.length())
            .mapNotNull { reminders.optJSONObject(it) }
            .firstOrNull { it.optInt("id") == id } ?: return

        val lastTriggered = JSONObject().apply {
            put("id", id)
            put("type", matching.optString("type"))
            put("key", matching.optString("key"))
            put("triggeredAt", System.currentTimeMillis())
        }
        if (!prefs.edit().putString(LAST_TRIGGERED_KEY, lastTriggered.toString()).commit()) {
            android.util.Log.e(
                "ReminderAlarmReceiver",
                "Could not persist the active reminder for voice completion."
            )
        }
        postReminderNotification(context, matching)
        if (matching.optBoolean("daily")) {
            schedule(context, matching)
        } else {
            val remaining = JSONArray()
            for (index in 0 until reminders.length()) {
                val reminder = reminders.optJSONObject(index) ?: continue
                if (reminder.optInt("id") != id) remaining.put(reminder)
            }
            prefs.edit().putString(REMINDERS_KEY, remaining.toString()).apply()
        }

        val announcement = Intent(context, ReminderAnnouncementService::class.java).apply {
            action = ReminderAnnouncementService.ACTION_ANNOUNCE
            putExtra(ReminderAnnouncementService.EXTRA_TITLE, matching.optString("title"))
            putExtra(ReminderAnnouncementService.EXTRA_TEXT, matching.optString("body"))
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(announcement)
            } else {
                context.startService(announcement)
            }
        } catch (error: Exception) {
            android.util.Log.e(
                "ReminderAlarmReceiver",
                "Could not start the Malayalam reminder announcement.",
                error
            )
        }
    }

    private fun postReminderNotification(context: Context, reminder: JSONObject) {
        createNotificationChannels(context)
        val id = reminder.optInt("id")
        val openApp = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notification = NotificationCompat.Builder(
            context,
            "care_${reminder.optString("type")}"
        )
            .setContentTitle(reminder.optString("title"))
            .setContentText(reminder.optString("body"))
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(reminder.optString("body"))
            )
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openApp)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_VIBRATE)
            .build()
        try {
            context.getSystemService(NotificationManager::class.java).notify(id, notification)
        } catch (error: SecurityException) {
            android.util.Log.w(
                "ReminderAlarmReceiver",
                "Notification permission is disabled; the spoken reminder may still run.",
                error
            )
        }
    }
}
