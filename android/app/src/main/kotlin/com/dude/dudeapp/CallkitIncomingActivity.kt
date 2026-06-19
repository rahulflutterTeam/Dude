package com.dude.dudeapp

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class CallkitIncomingActivity : Activity() {

    private var callId: String? = null
    private var callerName: String? = null
    private var callerId: String? = null
    private var isVideo: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wake up device and show on lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // Keep screen on and dismiss keyguard
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Get call data from intent
        callId = intent.getStringExtra("callId")
        callerName = intent.getStringExtra("callerName")
        callerId = intent.getStringExtra("callerId")
        isVideo = intent.getBooleanExtra("isVideo", false)

        // Create full-screen UI
        createFullScreenUI()

        // Wake lock to ensure screen turns on
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
            "Dude:IncomingCall"
        )
        wakeLock.acquire(10000)
    }

    private fun createFullScreenUI() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1A1A2E"))
            gravity = Gravity.CENTER
        }

        val callerNameText = TextView(this).apply {
            text = callerName ?: "Incoming Call"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        val callTypeText = TextView(this).apply {
            text = if (isVideo) "Incoming Video Call" else "Incoming Voice Call"
            textSize = 18f
            setTextColor(Color.parseColor("#CCCCCC"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 100)
        }

        val buttonLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }

        val acceptButton = Button(this).apply {
            text = "Accept"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#4CAF50"))
            setPadding(60, 25, 60, 25)
            textSize = 18f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(30, 0, 30, 0)
            }
            setOnClickListener { acceptCall() }
        }

        val declineButton = Button(this).apply {
            text = "Decline"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#F44336"))
            setPadding(60, 25, 60, 25)
            textSize = 18f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(30, 0, 30, 0)
            }
            setOnClickListener { declineCall() }
        }

        buttonLayout.addView(acceptButton)
        buttonLayout.addView(declineButton)

        layout.addView(callerNameText)
        layout.addView(callTypeText)
        layout.addView(buttonLayout)

        setContentView(layout)
    }

    private fun acceptCall() {
        // Store call data
        MyFirebaseMessagingService.pendingCallId = callId
        MyFirebaseMessagingService.pendingCallerName = callerName
        MyFirebaseMessagingService.pendingCallerId = callerId
        MyFirebaseMessagingService.pendingIsVideo = isVideo

        // Launch main activity
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("callId", callId)
            putExtra("callerName", callerName)
            putExtra("callerId", callerId)
            putExtra("isVideo", isVideo)
            putExtra("fromNotification", true)
        }
        startActivity(intent)
        finish()
    }

    private fun declineCall() {
        // Send decline broadcast to CallKit
        val intent = Intent("com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE")
        intent.putExtra("EXTRA_CALLKIT_ID", callId)
        sendBroadcast(intent)
        finish()
    }
}