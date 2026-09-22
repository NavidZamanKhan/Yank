package com.example.yank

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.yank/share_receiver"
    private val prefsName = "com.example.yank.share_prefs"
    private val shareKey = "ShareKey"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            when (call.method) {
                "getPendingShares" -> {
                    val pendingJson = prefs.getString(shareKey, null)
                    result.success(pendingJson)
                }
                "clearPendingShares" -> {
                    prefs.edit().remove(shareKey).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
