package com.fortress.studio.app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.ServiceCompat

class FortressForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ServiceCompat.startForegroundService(this, Intent(this, FortressForegroundService::class.java))
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
