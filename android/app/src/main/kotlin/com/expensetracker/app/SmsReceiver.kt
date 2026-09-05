package com.expensetracker.app

import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.provider.Telephony
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import java.util.UUID
import java.util.regex.Pattern

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                val sender = sms.displayOriginatingAddress ?: ""
                val body = sms.displayMessageBody ?: ""
                processBankSMS(context, sender, body)
            }
        }
    }

    private fun processBankSMS(context: Context, sender: String, body: String) {
        val lower = body.lowercase()
        val isDebit = lower.contains("debited") || lower.contains("spent") || lower.contains("paid") || lower.contains("withdrawn")
        val isCredit = lower.contains("credited") || lower.contains("deposited") || lower.contains("refunded") || lower.contains("salary")

        if (!isDebit && !isCredit) return // Not a bank transaction

        // Extract Amount
        val amountPattern = Pattern.compile("""(?:Rs\.?|INR|\$|€|debited by|credited by)\s*([0-9,]+(?:\.[0-9]{1,2})?)""", Pattern.CASE_INSENSITIVE)
        val matcher = amountPattern.matcher(body)
        if (!matcher.find()) return

        val amountStr = matcher.group(1)?.replace(",", "") ?: return
        val amount = amountStr.toDoubleOrNull() ?: return

        // Extract Merchant / Destination
        var merchant = "Bank Transaction"
        val merchantPattern = Pattern.compile("""(?:at|to|towards|info)\s+([A-Za-z0-9\s&.\-_]+?)(?=\s+(?:on|using|ref|bal|avl|\.|$))""", Pattern.CASE_INSENSITIVE)
        val mMatcher = merchantPattern.matcher(body)
        if (mMatcher.find()) {
            val m = mMatcher.group(1)?.trim()
            if (!m.isNullOrEmpty() && !m.lowercase().startsWith("a/c")) {
                merchant = m
            }
        }

        // Auto-categorize
        var categoryId = if (isCredit) "salary" else "food"
        if (lower.contains("uber") || lower.contains("fuel") || lower.contains("petrol")) categoryId = "transport"
        else if (lower.contains("blinkit") || lower.contains("grocery") || lower.contains("supermarket")) categoryId = "groceries"
        else if (lower.contains("amazon") || lower.contains("flipkart")) categoryId = "shopping"
        else if (lower.contains("netflix") || lower.contains("movie")) categoryId = "entertainment"
        else if (lower.contains("bill") || lower.contains("electricity")) categoryId = "bills"

        // Insert into Local SQLite Database directly
        try {
            val dbPath = context.getDatabasePath("expense_tracker.db")
            if (dbPath.exists()) {
                val db = SQLiteDatabase.openDatabase(dbPath.path, null, SQLiteDatabase.OPEN_READWRITE)
                val values = ContentValues().apply {
                    put("id", UUID.randomUUID().toString())
                    put("amount", amount)
                    put("type", if (isCredit) "income" else "expense")
                    put("category_id", categoryId)
                    put("merchant", merchant)
                    put("date", System.currentTimeMillis())
                    put("note", "Auto-parsed by Android Background Receiver")
                    put("raw_sms", body)
                    put("bank_name", sender)
                    put("payment_mode", if (lower.contains("upi")) "upi" else "debitCard")
                    put("is_auto_parsed", 1)
                }
                db.insertWithOnConflict("transactions", null, values, SQLiteDatabase.CONFLICT_REPLACE)
                db.close()
            }
        } catch (e: Exception) {
            // Log silently
        }

        // Notify user
        showNotification(context, amount, merchant, isCredit)
    }

    private fun showNotification(context: Context, amount: Double, merchant: String, isCredit: Boolean) {
        val channelId = "bank_sms_channel"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Bank SMS Alerts", NotificationManager.IMPORTANCE_HIGH)
            manager.createNotificationChannel(channel)
        }

        val typeStr = if (isCredit) "Income Logged" else "Expense Logged"
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Auto-$typeStr: ₹${String.format("%.2f", amount)}")
            .setContentText("Transaction at $merchant recorded in local database.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
