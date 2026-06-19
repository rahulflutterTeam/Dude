package com.dude.dudeapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
import java.util.UUID

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "MyFCMService"
        private const val PREFS_PUSH = "push_notification_state"
        private const val PREF_LAST_KEY = "last_notification_key"
        private const val PREF_LAST_TIME = "last_notification_time"
        private const val DUPLICATE_WINDOW_MS = 2 * 60 * 1000L

        const val CHANNEL_CHAT  = "chat_messages"
        const val CHANNEL_PROMO = "promo_channel"

        // Kept for call-related usage elsewhere in your app
        @Volatile var pendingCallId: String?     = null
        @Volatile var pendingCallerName: String? = null
        @Volatile var pendingCallerId: String?   = null
        @Volatile var pendingIsVideo: Boolean    = false
        @Volatile var pendingAction: String?     = null
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        val data = message.data
        Log.d(TAG, "FCM received: ${data.keys}")

        // ── 1. Extract call fields (your existing logic, unchanged) ───────────
        var callId     = data["call_id"] ?: data["callID"]
        var callerName = data["caller_name"] ?: "Incoming Call"
        var callerId   = data["caller_id"] ?: ""
        var isVideo    = data["call_type"] == "1"

        if (callId == null) {
            try {
                val json = JSONObject(data["payload"] ?: "{}")
                callId = listOf("call_id", "callID", "invitationID")
                    .map { json.optString(it) }.firstOrNull { it.isNotEmpty() }
                callerName = json.optString("caller_name", callerName)
                callerId   = json.optString("caller_id", callerId)
            } catch (e: Exception) {
                Log.e(TAG, "payload parse error: $e")
            }
        }

        if (callId.isNullOrEmpty()) callId = UUID.randomUUID().toString()

        pendingCallId     = callId
        pendingCallerName = callerName
        pendingCallerId   = callerId
        pendingIsVideo    = isVideo

        Log.d(TAG, "Stored — callId: $callId | caller: $callerName")

        // ── 2. If this is a Zego call invitation, let Zego handle the UI ──────
        if (isZegoCallInvitation(data)) {
            Log.d(TAG, "Zego call invitation — skipping custom notification")
            return
        }

        // ── 3. Get notification content ───────────────────────────────────────
        val n = message.notification
        if (n != null || hasFcmNotificationPayload(data)) {
            Log.d(TAG, "FCM notification payload received — Android system display path will handle it")
            return
        }

        val title = data["title"] ?: return   // nothing to show
        val body  = data["body"]  ?: return

        // ── 4. Ensure channels exist, then show the right notification ─────────
        ensureChannelsExist()

        if (isChatMessage(data)) {
            showChatNotification(title, body, notificationKey(CHANNEL_CHAT, title, body, data))
        } else {
            showPromoNotification(title, body, notificationKey(CHANNEL_PROMO, title, body, data))
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "FCM token refreshed: $token")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Chat notification → message_tone.mp3
    // ─────────────────────────────────────────────────────────────────────────
    private fun showChatNotification(title: String, body: String, notificationKey: String) {
        if (isDuplicate(notificationKey)) return

        val soundUri = Uri.parse("android.resource://$packageName/raw/message_tone")

        val intent = packageManager.getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pi = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_CHAT)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setSound(soundUri)                        // ← message_tone
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pi)
            .build()

        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mgr.notify(notificationId(notificationKey), notification)
        Log.d(TAG, "Chat notification shown with message_tone")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Promo notification → system default sound
    // ─────────────────────────────────────────────────────────────────────────
    private fun showPromoNotification(title: String, body: String, notificationKey: String) {
        if (isDuplicate(notificationKey)) return

        val intent = packageManager.getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pi = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_PROMO)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pi)
            .build()

        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mgr.notify(notificationId(notificationKey), notification)
        Log.d(TAG, "Promo notification shown with default sound")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Create channels only once — Android ignores duplicate calls,
    // but we guard with a null-check so sound is never overwritten
    // ─────────────────────────────────────────────────────────────────────────
    private fun ensureChannelsExist() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Chat channel
        if (mgr.getNotificationChannel(CHANNEL_CHAT) == null) {
            val soundUri = Uri.parse("android.resource://$packageName/raw/message_tone")
            val audioAttr = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val ch = NotificationChannel(
                CHANNEL_CHAT, "Chat Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming chat message notifications"
                setSound(soundUri, audioAttr)
                enableVibration(true)
            }
            mgr.createNotificationChannel(ch)
            Log.d(TAG, "Created chat_messages channel")
        }

        // Promo channel
        if (mgr.getNotificationChannel(CHANNEL_PROMO) == null) {
            val ch = NotificationChannel(
                CHANNEL_PROMO, "Promotions",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Promotional and announcement notifications"
            }
            mgr.createNotificationChannel(ch)
            Log.d(TAG, "Created promo_channel")
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────
    private fun isChatMessage(data: Map<String, String>): Boolean {
        val screen = data["screen"]?.lowercase() ?: ""
        if (screen == "chat" || screen == "message" || screen == "messages") return true
        return listOf(
            "senderId", "sender_id", "senderUserID",
            "conversationId", "conversationID", "conversation_id"
        ).any { data[it]?.isNotBlank() == true }
    }

    private fun isZegoCallInvitation(data: Map<String, String>): Boolean {
        if (data.containsKey("call_id") || data.containsKey("callID")) return true
        val payload = data["payload"] ?: return false
        return payload.contains("call_id") ||
                payload.contains("callID") ||
                payload.contains("invitationID")
    }

    private fun hasFcmNotificationPayload(data: Map<String, String>): Boolean {
        if (data["google.c.a.e"] == "1") return true
        return data.keys.any { key ->
            key.startsWith("gcm.n.") ||
                    key.startsWith("gcm.notification.") ||
                    key.startsWith("google.notification.")
        }
    }

    private fun notificationKey(
        channel: String,
        title: String,
        body: String,
        data: Map<String, String>
    ): String {
        val explicitKey = data["notification_id"]
            ?: data["notificationId"]
            ?: data["message_id"]
            ?: data["messageId"]

        return if (!explicitKey.isNullOrBlank()) {
            "$channel|$explicitKey"
        } else {
            "$channel|${title.trim()}|${body.trim()}"
        }
    }

    private fun notificationId(notificationKey: String): Int {
        return notificationKey.hashCode() and 0x7fffffff
    }

    private fun isDuplicate(notificationKey: String): Boolean {
        val now = System.currentTimeMillis()
        val prefs = getSharedPreferences(PREFS_PUSH, Context.MODE_PRIVATE)
        val lastKey = prefs.getString(PREF_LAST_KEY, null)
        val lastTime = prefs.getLong(PREF_LAST_TIME, 0L)

        if (lastKey == notificationKey && now - lastTime <= DUPLICATE_WINDOW_MS) {
            Log.d(TAG, "Duplicate notification suppressed")
            return true
        }

        prefs.edit()
            .putString(PREF_LAST_KEY, notificationKey)
            .putLong(PREF_LAST_TIME, now)
            .apply()
        return false
    }
}
