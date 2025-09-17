package com.example.smartlock

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.focushero/app_blocker"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(null)
                }
                "getCurrentForegroundApp" -> {
                    result.success(getCurrentForegroundApp())
                }
                "startBlocking" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps")
                    startBlockingService(blockedApps ?: emptyList())
                    result.success(null)
                }
                "stopBlocking" -> {
                    stopBlockingService()
                    result.success(null)
                }
                "minimizeApp" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOpsManager.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun getCurrentForegroundApp(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 // 1 minute ago

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        if (usageStatsList.isNullOrEmpty()) return null

        var recentApp: android.app.usage.UsageStats? = null
        for (usageStats in usageStatsList) {
            if (recentApp == null || usageStats.lastTimeUsed > recentApp.lastTimeUsed) {
                recentApp = usageStats
            }
        }

        // Check if the app was used in the last 5 seconds
        if (recentApp != null && (endTime - recentApp.lastTimeUsed) < 5000) {
            return recentApp.packageName
        }

        return null
    }

    private fun startBlockingService(blockedApps: List<String>) {
        val intent = Intent(this, AppBlockerService::class.java).apply {
            action = "START_BLOCKING"
            putStringArrayListExtra("BLOCKED_APPS", ArrayList(blockedApps))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopBlockingService() {
        val intent = Intent(this, AppBlockerService::class.java)
        stopService(intent)
    }
}