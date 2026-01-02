package com.example.texxxx

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.smsapp/sms"
    private val SMS_PERMISSION_CODE = 101

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInboxSms" -> {
                    if (checkSmsPermission()) {
                        val messages = getInboxSms()
                        result.success(messages)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun getInboxSms(): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        
        try {
            val uri = Uri.parse("content://sms/inbox")
            val cursor: Cursor? = contentResolver.query(
                uri,
                arrayOf("_id", "address", "body", "date"),
                null,
                null,
                "date DESC"
            )

            cursor?.use {
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                val dateIndex = it.getColumnIndex("date")

                while (it.moveToNext()) {
                    val message = mapOf(
                        "address" to (it.getString(addressIndex) ?: "Unknown"),
                        "body" to (it.getString(bodyIndex) ?: ""),
                        "date" to it.getLong(dateIndex)
                    )
                    messages.add(message)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return messages
    }
}