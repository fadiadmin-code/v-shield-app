package com.example.v_shield

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import java.net.URLEncoder
import tun2socks.Tun2socks

class VoidVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val CHANNEL_ID = "v_shield_vpn_channel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        startForegroundNotification()

        val type = intent?.getStringExtra("type") ?: "socks5"
        val host = intent?.getStringExtra("host") ?: ""
        val port = intent?.getIntExtra("port", 1080) ?: 1080
        val user = intent?.getStringExtra("user") ?: ""
        val pass = intent?.getStringExtra("pass") ?: ""

        startVpn(type, host, port, user, pass)
        return START_STICKY
    }

    private fun startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "V-SHIELD VPN Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
            val notification = Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("V-SHIELD Active")
                .setContentText("Void Protocol Tunnel is running")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .build()
            startForeground(1, notification)
        }
    }

    private fun startVpn(type: String, host: String, port: Int, user: String, pass: String) {
        if (vpnInterface != null || host.isEmpty()) return

        val builder = Builder()
            .setSession("V-SHIELD Void Protocol")
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .setMtu(1500)

        try {
            builder.addDisallowedApplication(packageName)
        } catch (_: Exception) {}

        vpnInterface = builder.establish()
        val fd = vpnInterface?.fd ?: return

        val scheme = type.lowercase()
        val auth = if (user.isNotEmpty() && pass.isNotEmpty()) {
            val u = URLEncoder.encode(user, "UTF-8")
            val p = URLEncoder.encode(pass, "UTF-8")
            "$u:$p@"
        } else ""
        val proxyUrl = "$scheme://$auth$host:$port"

        Thread {
            try {
                Tun2socks.start(fd.toLong(), proxyUrl, 1500L)
            } catch (_: Exception) {}
        }.start()
    }

    private fun stopVpn() {
        try {
            Tun2socks.stop()
        } catch (_: Exception) {}
        try {
            vpnInterface?.close()
        } catch (_: Exception) {}
        vpnInterface = null
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
