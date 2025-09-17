package com.example.smartlock

import android.app.*
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.util.*
import kotlin.concurrent.timer

class AppBlockerService : Service() {
    private var timer: Timer? = null
    private var blockedApps: List<String> = emptyList()
    private val CHANNEL_ID = "FocusHeroBlocker"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_BLOCKING" -> {
                blockedApps = intent.getStringArrayListExtra("BLOCKED_APPS") ?: emptyList()
                startForeground(NOTIFICATION_ID, createNotification())
                startMonitoring()
            }
            else -> {
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Focus Hero is blocking distracting apps"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus Mode Active")
            .setContentText("Blocking ${blockedApps.size} apps")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startMonitoring() {
        timer?.cancel()
        timer = timer(period = 1000) {
            checkForegroundApp()
        }
    }

    private fun checkForegroundApp() {
        val currentApp = getForegroundApp()
        if (currentApp != null && currentApp in blockedApps) {
            // Send user back to launcher
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)

            // Show toast or notification
            showBlockedNotification(currentApp)
        }
    }

    private fun getForegroundApp(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 // 1 minute ago

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        if (usageStatsList.isNullOrEmpty()) return null

        var recentApp: UsageStats? = null
        for (usageStats in usageStatsList) {
            if (recentApp == null || usageStats.lastTimeUsed > recentApp.lastTimeUsed) {
                recentApp = usageStats
            }
        }

        return recentApp?.packageName
    }

    private fun showBlockedNotification(appPackage: String) {
        val notificationManager = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("App Blocked")
            .setContentText("$appPackage is blocked during focus time")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(2, notification)
    }

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}