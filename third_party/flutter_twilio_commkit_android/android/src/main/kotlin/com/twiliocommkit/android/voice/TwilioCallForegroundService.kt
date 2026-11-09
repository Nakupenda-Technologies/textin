package com.twiliocommkit.android.voice

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground service to keep voice calls alive on Android while the app
 * is in the background. Required for Android 8+ background restrictions.
 */
class TwilioCallForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "twilio_call_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "ACTION_START_CALL"
        const val ACTION_STOP = "ACTION_STOP_CALL"
        const val EXTRA_CALLER = "EXTRA_CALLER"
        /** When true the service runs as microphone type (publisher); otherwise
         *  mediaPlayback type (listener — may not hold RECORD_AUDIO). */
        const val EXTRA_USES_MICROPHONE = "EXTRA_USES_MICROPHONE"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val caller = intent.getStringExtra(EXTRA_CALLER) ?: "Unknown"
                // Android 10+ requires the explicit microphone service type for the
                // mic to keep capturing while the app is in the background. Listeners
                // (no published audio) use mediaPlayback so remote audio survives
                // backgrounding without needing RECORD_AUDIO.
                val usesMic = intent.getBooleanExtra(EXTRA_USES_MICROPHONE, true)
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    if (usesMic) ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                    else ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                } else 0
                ServiceCompat.startForeground(
                    this, NOTIFICATION_ID, buildNotification(caller), type
                )
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(caller: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Active Call")
            .setContentText("In call with $caller")
            .setSmallIcon(TwilioNotificationConfig.resolveSmallIconRes(this))
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active Calls",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Keeps active calls running in the background"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}

