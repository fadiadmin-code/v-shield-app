package com.example.v_shield

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku

class MainActivity : FlutterActivity() {
    private val CHANNEL = "v_shield/vpn"
    private val VPN_REQUEST_CODE = 1001
    private val SHIZUKU_REQUEST_CODE = 1002
    private var pendingType = "socks5"
    private var pendingHost = ""
    private var pendingPort = 1080
    private var pendingUser = ""
    private var pendingPass = ""
    private var pendingResult: MethodChannel.Result? = null

    private val gpsHandler = Handler(Looper.getMainLooper())
    private var gpsRunnable: Runnable? = null

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
                    stopMockLocationLoop()
                    val intent = Intent(this, VoidVpnService::class.java).apply { action = "STOP" }
                    startService(intent)
                    result.success(true)
                }
                "setMockLocation" -> {
                    val lat = call.argument<Double>("lat") ?: 0.0
                    val lon = call.argument<Double>("lon") ?: 0.0
                    result.success(startMockLocationLoop(lat, lon))
                }
                "runShizukuCmd" -> {
                    val cmd = call.argument<String>("cmd") ?: ""
                    result.success(executeShizukuCommand(cmd))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun executeShizukuCommand(cmd: String): String {
        return try {
            if (!Shizuku.pingBinder()) {
                return "SHIZUKU_NOT_RUNNING"
            }
            if (Shizuku.checkSelfPermission() != PackageManager.PERMISSION_GRANTED) {
                Shizuku.requestPermission(SHIZUKU_REQUEST_CODE)
                return "PERMISSION_REQUESTED"
            }
            val method = Shizuku::class.java.getDeclaredMethod(
                "newProcess",
                Array<String>::class.java,
                Array<String>::class.java,
                String::class.java
            )
            method.isAccessible = true
            val process = method.invoke(null, arrayOf("sh", "-c", cmd), null, null) as Process
            process.waitFor()
            if (process.exitValue() == 0) "OK" else "ERR_${process.exitValue()}"
        } catch (e: Throwable) {
            "ERROR: ${e.message}"
        }
    }

    @Suppress("DEPRECATION")
    private fun pushProviderLocation(lm: LocationManager, provider: String, lat: Double, lon: Double) {
        try {
            try {
                lm.addTestProvider(
                    provider, false, false, false, false, true, true, true,
                    Criteria.POWER_LOW, Criteria.ACCURACY_FINE
                )
            } catch (_: Throwable) {}
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
        } catch (_: Throwable) {}
    }

    private fun startMockLocationLoop(lat: Double, lon: Double): Boolean {
        stopMockLocationLoop()
        return try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            try {
                lm.removeTestProvider(LocationManager.GPS_PROVIDER)
            } catch (_: Throwable) {}
            @Suppress("DEPRECATION")
            lm.addTestProvider(
                LocationManager.GPS_PROVIDER, false, false, false, false, true, true, true,
                Criteria.POWER_LOW, Criteria.ACCURACY_FINE
            )

            gpsRunnable = object : Runnable {
                override fun run() {
                    pushProviderLocation(lm, LocationManager.GPS_PROVIDER, lat, lon)
                    pushProviderLocation(lm, LocationManager.NETWORK_PROVIDER, lat, lon)
                    gpsHandler.postDelayed(this, 1000)
                }
            }
            gpsHandler.post(gpsRunnable!!)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun stopMockLocationLoop() {
        gpsRunnable?.let { gpsHandler.removeCallbacks(it) }
        gpsRunnable = null
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

    override fun onDestroy() {
        stopMockLocationLoop()
        super.onDestroy()
    }
}
