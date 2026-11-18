package com.example.v_shield

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor

class VoidVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        val host = intent?.getStringExtra("host") ?: ""
        val port = intent?.getIntExtra("port", 1080) ?: 1080

        startVpn(host, port)
        return START_STICKY
    }

    private fun startVpn(host: String, port: Int) {
        if (vpnInterface != null) return

        val builder = Builder()
            .setSession("V-SHIELD Void Protocol")
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .setMtu(1500)

        // استثناء التطبيق نفسه لمنع التكرار الحلقي
        try {
            builder.addDisallowedApplication(packageName)
        } catch (_: Exception) {}

        vpnInterface = builder.establish()
    }

    private fun stopVpn() {
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
