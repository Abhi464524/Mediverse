package com.example.mediverse

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.mediverse/phone"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDialer" -> {
                    val raw = call.argument<String>("number")
                    if (raw.isNullOrBlank()) {
                        result.error("ARG", "number is required", null)
                        return@setMethodCallHandler
                    }
                    val sanitized = raw.replace("\\s+".toRegex(), "")
                    try {
                        val intent = Intent(Intent.ACTION_DIAL).apply {
                            data = Uri.parse("tel:$sanitized")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        result.error("NO_DIALER", e.message, null)
                    } catch (e: Exception) {
                        result.error("DIAL", e.message, null)
                    }
                }
                "placeCall" -> {
                    val raw = call.argument<String>("number")
                    if (raw.isNullOrBlank()) {
                        result.error("ARG", "number is required", null)
                        return@setMethodCallHandler
                    }
                    val sanitized = raw.replace("\\s+".toRegex(), "")
                    try {
                        val intent = Intent(Intent.ACTION_CALL).apply {
                            data = Uri.parse("tel:$sanitized")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.error("PERM", e.message, null)
                    } catch (e: ActivityNotFoundException) {
                        result.error("NO_APP", e.message, null)
                    } catch (e: Exception) {
                        result.error("CALL", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
