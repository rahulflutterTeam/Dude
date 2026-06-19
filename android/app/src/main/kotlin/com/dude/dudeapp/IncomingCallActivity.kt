package com.dude.dudeapp

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.LinearLayout
import android.view.Gravity
import android.graphics.Color
import android.util.Log

class IncomingCallActivity : Activity() {

    companion object {
        private const val TAG = "IncomingCallActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d(TAG, "IncomingCallActivity CREATED!")

        val callId = intent.getStringExtra("callId")
        val callerName = intent.getStringExtra("callerName") ?: "Unknown"

        Log.d(TAG, "CallId: $callId, Caller: $callerName")

        // Show on lock screen
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

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Create simple UI
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            gravity = Gravity.CENTER
        }

        val nameText = TextView(this).apply {
            text = callerName
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(50, 0, 50, 50)
        }

        val statusText = TextView(this).apply {
            text = "Incoming Voice Call"
            textSize = 18f
            setTextColor(Color.GRAY)
            gravity = Gravity.CENTER
            setPadding(50, 0, 50, 50)
        }

        val acceptButton = Button(this).apply {
            text = "ACCEPT"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#4CAF50"))
            setPadding(80, 30, 80, 30)
            textSize = 20f
            setOnClickListener {
                Log.d(TAG, "Accept clicked")
                // Launch main activity
                val intent = Intent(this@IncomingCallActivity, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("fromNotification", true)
                    putExtra("callId", callId)
                }
                startActivity(intent)
                finish()
            }
        }

        val declineButton = Button(this).apply {
            text = "DECLINE"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#F44336"))
            setPadding(80, 30, 80, 30)
            textSize = 20f
            setOnClickListener {
                Log.d(TAG, "Decline clicked")
                finish()
            }
        }

        val buttonLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(acceptButton)
            addView(declineButton)
        }

        layout.addView(nameText)
        layout.addView(statusText)
        layout.addView(buttonLayout)

        setContentView(layout)

        // Wake device
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "Dude:IncomingCall"
        )
        wakeLock.acquire(10000)
    }
}