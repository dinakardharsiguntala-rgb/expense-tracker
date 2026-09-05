package com.expensetracker.app

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.expensetracker.app/sms"
    private val SMS_PERMISSION_CODE = 101

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermissions" -> {
                    val hasReceive = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    val hasRead = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    result.success(hasReceive && hasRead)
                }
                "requestPermissions" -> {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS),
                        SMS_PERMISSION_CODE
                    )
                    result.success(true)
                }
                "getHistoricalSms" -> {
                    val messages = readSmsInbox()
                    result.success(messages)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readSmsInbox(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            return list
        }

        val uri = Uri.parse("content://sms/inbox")
        val cursor = contentResolver.query(uri, arrayOf("address", "body", "date"), null, null, "date DESC LIMIT 50")
        cursor?.use {
            val addressIdx = it.getColumnIndex("address")
            val bodyIdx = it.getColumnIndex("body")
            while (it.moveToNext()) {
                val address = if (addressIdx != -1) it.getString(addressIdx) else ""
                val body = if (bodyIdx != -1) it.getString(bodyIdx) else ""
                list.add(mapOf("sender" to address, "body" to body))
            }
        }
        return list
    }
}

