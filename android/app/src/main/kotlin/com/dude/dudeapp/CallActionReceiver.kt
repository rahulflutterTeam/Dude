package com.dude.dudeapp

// Place at:
// android/app/src/main/kotlin/com/dude/dudeapp/CallActionReceiver.kt
//
// This receiver handles Accept/Decline taps from the backup notification.
// For the main CallKit UI, flutter_callkit_incoming handles its own actions.

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class CallActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallActionReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action   = intent.action ?: return
        val callId   = intent.getStringExtra("callId") ?: ""

        Log.d(TAG, "Action: $action  callId: $callId")

        when (action) {
            "ACCEPT_CALL" -> {
                // Store accepted state so Zego can accept when app resumes
                MyFirebaseMessagingService.pendingCallId     = callId
                MyFirebaseMessagingService.pendingCallerName = intent.getStringExtra("callerName")
                MyFirebaseMessagingService.pendingCallerId   = intent.getStringExtra("callerId")
                MyFirebaseMessagingService.pendingIsVideo    = intent.getBooleanExtra("isVideo", false)

                // Launch MainActivity so Zego can connect the call
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("fromNotification", true)
                    putExtra("callId", callId)
                }
                context.startActivity(launchIntent)
            }

            "DECLINE_CALL" -> {
                // Clear pending state
                MyFirebaseMessagingService.pendingCallId = null
                Log.d(TAG, "Call declined from notification")
            }
        }
    }
}