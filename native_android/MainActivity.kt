package com.example.v_shield

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "v_shield/vpn"
    private val VPN_REQUEST_CODE = 1001
    private var pendingType = "socks5"
    private var pendingHost = ""
    private var pendingPort = 1080
    private var pendingUser = ""
    private var pendingPass = ""
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    pendingType = call.argument<String>("type") ?: "socks5"
                    pendingHost = call.argument<String>("host") ?: ""
                    pendingPort = call.argument<Int>("port") ?: 1080
                    pendingUser = call.argument<String>("user") ?: ""
                    pendingPass = call.argument<String>("pass") ?: ""

                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        pendingResult = result
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        launchVpnService()
                        result.success(true)
                    }
                }
                "stopVpn" -> {
                    val intent = Intent(this, VoidVpnService::class.java).apply { action = "STOP" }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchVpnService() {
        val intent = Intent(this, VoidVpnService::class.java).apply {
            putExtra("type", pendingType)
            putExtra("host", pendingHost)
            putExtra("port", pendingPort)
            putExtra("user", pendingUser)
            putExtra("pass", pendingPass)
        }
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                launchVpnService()
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
}
