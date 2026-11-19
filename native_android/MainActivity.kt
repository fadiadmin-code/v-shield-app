package com.example.v_shield

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.net.VpnService
import android.os.SystemClock
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
                "setMockLocation" -> {
                    val lat = call.argument<Double>("lat") ?: 0.0
                    val lon = call.argument<Double>("lon") ?: 0.0
                    result.success(applyMockLocation(lat, lon))
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun applyMockLocation(lat: Double, lon: Double): Boolean {
        return try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val provider = LocationManager.GPS_PROVIDER
            try {
                lm.removeTestProvider(provider)
            } catch (_: Throwable) {}
            lm.addTestProvider(
                provider, false, false, false, false, true, true, true,
                Criteria.POWER_LOW, Criteria.ACCURACY_FINE
            )
            lm.setTestProviderEnabled(provider, true)
            val loc = Location(provider).apply {
                latitude = lat
                longitude = lon
                altitude = 10.0
                accuracy = 1.0f
                time = System.currentTimeMillis()
                elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
            }
            lm.setTestProviderLocation(provider, loc)
            true
        } catch (_: Throwable) {
            false
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
