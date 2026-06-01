package com.karthik.local_hub

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.karthik.local_hub/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
                val manager = AppWidgetManager.getInstance(this)
                val ids = manager.getAppWidgetIds(
                    ComponentName(this, TodayWidget::class.java)
                )
                TodayWidget().onUpdate(this, manager, ids)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}