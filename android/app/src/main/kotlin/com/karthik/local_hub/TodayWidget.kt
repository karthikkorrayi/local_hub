package com.karthik.local_hub

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.view.View
import android.widget.RemoteViews
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class TodayWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val today = sdf.format(Date())
            val displaySdf = SimpleDateFormat("EEEE, MMM d", Locale.getDefault())
            views.setTextViewText(R.id.widget_date, displaySdf.format(Date()))

            try {
                val dbPath = getDbPath(context)
                if (dbPath != null && File(dbPath).exists()) {
                    val db = SQLiteDatabase.openDatabase(
                        dbPath, null, SQLiteDatabase.OPEN_READONLY
                    )

                    val moodCursor = db.rawQuery(
                        "SELECT mood FROM DayEntry WHERE date = ? LIMIT 1",
                        arrayOf(today)
                    )
                    if (moodCursor.moveToFirst()) {
                        val mood = moodCursor.getString(0) ?: ""
                        views.setTextViewText(R.id.widget_mood, mood)
                    }
                    moodCursor.close()

                    val eventCursor = db.rawQuery(
                        "SELECT title, startTime FROM CalendarEvent WHERE date = ? ORDER BY startTime ASC LIMIT 3",
                        arrayOf(today)
                    )

                    val events = mutableListOf<Pair<String, String>>()
                    while (eventCursor.moveToNext()) {
                        events.add(Pair(
                            eventCursor.getString(0) ?: "",
                            eventCursor.getString(1) ?: ""
                        ))
                    }
                    eventCursor.close()
                    db.close()

                    val rowIds = listOf(
                        Triple(R.id.event_1_row, R.id.event_1_title, R.id.event_1_time),
                        Triple(R.id.event_2_row, R.id.event_2_title, R.id.event_2_time),
                        Triple(R.id.event_3_row, R.id.event_3_title, R.id.event_3_time),
                    )

                    for (i in rowIds.indices) {
                        if (i < events.size) {
                            views.setViewVisibility(rowIds[i].first, View.VISIBLE)
                            views.setTextViewText(rowIds[i].second, events[i].first)
                            views.setTextViewText(rowIds[i].third,
                                events[i].second.ifEmpty { "All day" })
                        } else {
                            views.setViewVisibility(rowIds[i].first, View.GONE)
                        }
                    }

                    if (events.isEmpty()) {
                        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_empty, View.GONE)
                    }
                } else {
                    views.setTextViewText(R.id.widget_empty, "Open app to load data")
                    views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                }
            } catch (e: Exception) {
                views.setTextViewText(R.id.widget_empty, "Open app to refresh")
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        private fun getDbPath(context: Context): String? {
            val dataDir = context.applicationInfo.dataDir
            return "$dataDir/databases/local_hub.db"
        }
    }
}