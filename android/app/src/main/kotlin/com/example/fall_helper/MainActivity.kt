package com.example.fall_helper

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val phoneCallChannelName = "fall_helper/phone_call"
    private val videoConsolidationChannelName = "fall_helper/video_consolidation"
    private val requestCallPermissionCode = 1001

    private var pendingPhoneNumber: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            phoneCallChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "callPhoneNumber" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")

                    if (phoneNumber.isNullOrBlank()) {
                        result.error("INVALID_PHONE", "Número inválido.", null)
                        return@setMethodCallHandler
                    }

                    startDirectCall(phoneNumber, result)
                }

                else -> result.notImplemented()
            }
        }

        val consolidationBridge = VideoConsolidationBridge(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            videoConsolidationChannelName
        ).setMethodCallHandler { call, result ->
            consolidationBridge.handle(call, result)
        }
    }

    private fun startDirectCall(phoneNumber: String, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.CALL_PHONE
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            placeCall(phoneNumber, result)
            return
        }

        pendingPhoneNumber = phoneNumber
        pendingResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CALL_PHONE),
            requestCallPermissionCode
        )
    }

    private fun placeCall(phoneNumber: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_FAILED", "Não foi possível iniciar a chamada.", e.message)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != requestCallPermissionCode) return

        val result = pendingResult
        val phoneNumber = pendingPhoneNumber

        pendingResult = null
        pendingPhoneNumber = null

        if (result == null || phoneNumber.isNullOrBlank()) return

        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            placeCall(phoneNumber, result)
        } else {
            result.error(
                "PERMISSION_DENIED",
                "Permissão CALL_PHONE negada pelo utilizador.",
                null
            )
        }
    }
}