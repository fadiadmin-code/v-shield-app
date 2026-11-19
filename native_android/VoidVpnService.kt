package com.example.v_shield

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import tun2socks.Tun2socks

class VoidVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        val type = intent?.getStringExtra("type") ?: "socks5"
        val host = intent?.getStringExtra("host") ?: ""
        val port = intent?.getIntExtra("port", 1080) ?: 1080
        val user = intent?.getStringExtra("user") ?: ""
        val pass = intent?.getStringExtra("pass") ?: ""

        startVpn(type, host, port, user, pass)
        return START_STICKY
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
        val auth = if (user.isNotEmpty() && pass.isNotEmpty()) "$user:$pass@" else ""
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
        stopSelf()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
