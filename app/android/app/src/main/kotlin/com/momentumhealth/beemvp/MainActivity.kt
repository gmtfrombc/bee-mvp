package com.momentumhealth.beemvp

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Android Settings Plugin
        flutterEngine.plugins.add(AndroidSettingsPlugin())

        // Ensure notification channel for AI Coach push notifications exists
        createCoachNotificationChannel()
    }

    /**
     * Creates the notification channel "coach_push" for coach notifications on Android O+
     */
    private fun createCoachNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "coach_push"
            val channelName = "Coach Push"
            val descriptionText = "Notifications from the AI Coach"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = descriptionText
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
