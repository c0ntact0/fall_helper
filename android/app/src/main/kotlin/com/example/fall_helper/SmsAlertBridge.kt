package com.example.fall_helper

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmsAlertBridge(
    private val activity: FlutterActivity
) {
    private val requestSmsPermissionCode = 1002

    private var pendingPhoneNumber: String? = null
    private var pendingMessage: String? = null
    private var pendingResult: MethodChannel.Result? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sendSms" -> {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")

                if (phoneNumber.isNullOrBlank()) {
                    result.error("INVALID_PHONE", "Número inválido.", null)
                    return
                }

                if (message.isNullOrBlank()) {
                    result.error("INVALID_MESSAGE", "Mensagem inválida.", null)
                    return
                }

                sendSms(phoneNumber, message, result)
            }

            else -> result.notImplemented()
        }
    }

    private fun sendSms(
        phoneNumber: String,
        message: String,
        result: MethodChannel.Result
    ) {
        if (ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.SEND_SMS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            actuallySendSms(phoneNumber, message, result)
            return
        }

        pendingPhoneNumber = phoneNumber
        pendingMessage = message
        pendingResult = result

        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.SEND_SMS),
            requestSmsPermissionCode
        )
    }

    private fun actuallySendSms(
        phoneNumber: String,
        message: String,
        result: MethodChannel.Result
    ) {
        try {
            val smsManager = SmsManager.getDefault()
            val parts = smsManager.divideMessage(message)

            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(
                    phoneNumber,
                    null,
                    ArrayList(parts),
                    null,
                    null
                )
            } else {
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            }

            result.success(null)
        } catch (e: Exception) {
            result.error(
                "SMS_FAILED",
                "Não foi possível enviar o SMS.",
                e.message
            )
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != requestSmsPermissionCode) return false

        val result = pendingResult
        val phoneNumber = pendingPhoneNumber
        val message = pendingMessage

        pendingResult = null
        pendingPhoneNumber = null
        pendingMessage = null

        if (result == null || phoneNumber.isNullOrBlank() || message.isNullOrBlank()) {
            return true
        }

        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            actuallySendSms(phoneNumber, message, result)
        } else {
            result.error(
                "PERMISSION_DENIED",
                "Permissão SEND_SMS negada pelo utilizador.",
                null
            )
        }

        return true
    }
}