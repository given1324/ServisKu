package com.example.serviceku

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.serviceku/gps"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getCurrentLocation") {
                    val fineGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ) == PackageManager.PERMISSION_GRANTED
                    val coarseGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    ) == PackageManager.PERMISSION_GRANTED

                    if (fineGranted || coarseGranted) {
                        requestFreshLocation(result)
                    } else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            1001
                        )
                    }
                } else if (call.method == "openExternalUrl") {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrBlank()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            val res = pendingResult
            pendingResult = null
            if (res != null) {
                if (grantResults.isNotEmpty() && grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                    requestFreshLocation(res)
                } else {
                    res.success(null)
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun requestFreshLocation(result: MethodChannel.Result) {
        try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )

            var bestLocation: Location? = null
            val nowMs = System.currentTimeMillis()
            for (provider in providers) {
                try {
                    if (locationManager.isProviderEnabled(provider)) {
                        val loc = locationManager.getLastKnownLocation(provider)
                        if (loc != null) {
                            if (bestLocation == null || loc.accuracy < bestLocation.accuracy) {
                                bestLocation = loc
                            }
                        }
                    }
                } catch (_: Exception) {}
            }

            // Hanya gunakan cache langsung jika masih sangat baru (< 2 menit) DAN akurasinya tinggi (<= 60 meter)
            if (bestLocation != null &&
                (nowMs - bestLocation.time) < 120_000L &&
                bestLocation.hasAccuracy() &&
                bestLocation.accuracy <= 60f
            ) {
                result.success(mapOf("lat" to bestLocation.latitude, "lng" to bestLocation.longitude))
                return
            }

            // Minta pembacaan GPS satelit presisi tinggi + Network secara real-time
            var responded = false
            var bestFreshLocation: Location? = bestLocation
            val handler = Handler(Looper.getMainLooper())
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (bestFreshLocation == null || location.accuracy < bestFreshLocation!!.accuracy) {
                        bestFreshLocation = location
                    }
                    // Jika mendapat pembacaan presisi tinggi (<= 65m atau dari GPS satelit), langsung kirim
                    if (!responded && (location.provider == LocationManager.GPS_PROVIDER || location.accuracy <= 65f)) {
                        responded = true
                        locationManager.removeUpdates(this)
                        result.success(mapOf("lat" to location.latitude, "lng" to location.longitude))
                    }
                }
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }

            var anyProviderRegistered = false
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0L, 0f, listener, Looper.getMainLooper())
                anyProviderRegistered = true
            }
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 0L, 0f, listener, Looper.getMainLooper())
                anyProviderRegistered = true
            }

            if (anyProviderRegistered) {
                handler.postDelayed({
                    if (!responded) {
                        responded = true
                        locationManager.removeUpdates(listener)
                        val finalLoc = bestFreshLocation
                        if (finalLoc != null) {
                            result.success(mapOf("lat" to finalLoc.latitude, "lng" to finalLoc.longitude))
                        } else {
                            result.success(null)
                        }
                    }
                }, 4500)
            } else if (bestLocation != null) {
                result.success(mapOf("lat" to bestLocation.latitude, "lng" to bestLocation.longitude))
            } else {
                result.success(null)
            }
        } catch (_: Exception) {
            result.success(null)
        }
    }
}
