package com.dude.dudeapp

import android.app.Activity.RESULT_OK
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.dude.dudeapp/window"
    private val OTP_CHANNEL = "com.dude.dudeapp/otp_autofill"
    private val SMS_CONSENT_REQUEST = 7004

    private var otpChannel: MethodChannel? = null
    private var smsConsentReceiver: BroadcastReceiver? = null

    // When user presses back button, move app to background instead of
    // destroying it. This keeps socket + Zego connected so incoming calls
    // still work — exactly like WhatsApp behavior.
//    @Suppress("DEPRECATION")
//    override fun onBackPressed() {
//        moveTaskToBack(true)
//    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preventScreenshotsAndRecording()
        window.decorView.post {
            createNotificationChannels()
        }

        // Show over lock screen when user accepts a call from notification
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
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        intent?.let { handleIntent(it) }
    }
    private fun preventScreenshotsAndRecording() {
        // This works on all Android versions (API level 1+)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // General promo/announcement pushes (FCM notification payload)
        val promo = NotificationChannel(
            "promo_channel",
            "Promotions",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Promotional and announcement notifications"
        }

        // Existing channels used by your call/invitation stack
        val zegoCall = NotificationChannel(
            "zego_call_channel",
            "Incoming Calls",
            NotificationManager.IMPORTANCE_HIGH
        )
        val missedCall = NotificationChannel(
            "missed_call_channel",
            "Missed Calls",
            NotificationManager.IMPORTANCE_DEFAULT
        )

        nm.createNotificationChannel(promo)
        nm.createNotificationChannel(zegoCall)
        nm.createNotificationChannel(missedCall)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.getBooleanExtra("fromNotification", false)) {
            MyFirebaseMessagingService.pendingCallId     = intent.getStringExtra("callId")
            MyFirebaseMessagingService.pendingCallerName = intent.getStringExtra("callerName")
            MyFirebaseMessagingService.pendingCallerId   = intent.getStringExtra("callerId")
            MyFirebaseMessagingService.pendingIsVideo    = intent.getBooleanExtra("isVideo", false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Intercept and stub screen_brightness MethodChannel calls to prevent screen brightness overrides/locks
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "github.com/aaassseee/screen_brightness")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemScreenBrightness" -> result.success(0.5)
                    "getScreenBrightness" -> result.success(0.5)
                    "setScreenBrightness" -> result.success(null)
                    "resetScreenBrightness" -> result.success(null)
                    "hasChanged" -> result.success(false)
                    "isAutoReset" -> result.success(true)
                    "setAutoReset" -> result.success(null)
                    else -> result.notImplemented()
                }
            }

        otpChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OTP_CHANNEL)
        otpChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startSmsUserConsent" -> startSmsUserConsent(result)
                "stopSmsUserConsent" -> {
                    stopSmsUserConsent()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }

                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (!Settings.canDrawOverlays(this)) {
                                startActivity(Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                ))
                            }
                        }
                        result.success(null)
                    }

                    "isOverlayPermissionGranted" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else { true }
                        result.success(granted)
                    }

                    // ── KEY: Opens the full-screen intent permission settings ──
                    // Android 14+ requires user to explicitly grant this.
                    // Without it → notification only, no WhatsApp-style call screen.
                    "openFullScreenIntentSettings" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            try {
                                // Use string literal — constant not available in all SDK versions
                                val intent = Intent(
                                    "android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENT",
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                            } catch (e: Exception) {
                                // Fallback to general notification settings
                                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                }
                                startActivity(intent)
                            }
                        }
                        result.success(null)
                    }

                    "getAcceptedCallData" -> {
                        val callId = MyFirebaseMessagingService.pendingCallId
                        if (callId != null) {
                            result.success(mapOf(
                                "callId"     to callId,
                                "callerName" to (MyFirebaseMessagingService.pendingCallerName ?: ""),
                                "callerId"   to (MyFirebaseMessagingService.pendingCallerId   ?: ""),
                                "isVideo"    to MyFirebaseMessagingService.pendingIsVideo
                            ))
                            MyFirebaseMessagingService.pendingCallId = null
                        } else {
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun startSmsUserConsent(result: MethodChannel.Result) {
        stopSmsUserConsent()

        smsConsentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (SmsRetriever.SMS_RETRIEVED_ACTION != intent.action) return

                val status = intent.extras?.get(SmsRetriever.EXTRA_STATUS) as? Status
                when (status?.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        val message = intent.extras
                            ?.getString(SmsRetriever.EXTRA_SMS_MESSAGE)
                            .orEmpty()
                        if (emitOtpFromMessage(message)) {
                            stopSmsUserConsent()
                            return
                        }

                        val consentIntent = intent.extras
                            ?.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                        if (consentIntent != null) {
                            try {
                                @Suppress("DEPRECATION")
                                startActivityForResult(consentIntent, SMS_CONSENT_REQUEST)
                            } catch (e: ActivityNotFoundException) {
                                otpChannel?.invokeMethod("onOtpAutofillError", e.message)
                            }
                        }
                    }
                    CommonStatusCodes.TIMEOUT -> {
                        otpChannel?.invokeMethod("onOtpAutofillTimeout", null)
                    }
                }
            }
        }

        val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        ContextCompat.registerReceiver(
            this,
            smsConsentReceiver,
            filter,
            SmsRetriever.SEND_PERMISSION,
            null,
            ContextCompat.RECEIVER_EXPORTED
        )

        SmsRetriever.getClient(this)
            .startSmsRetriever()
            .addOnFailureListener { error ->
                otpChannel?.invokeMethod("onOtpAutofillError", error.message)
            }

        SmsRetriever.getClient(this)
            .startSmsUserConsent(null)
            .addOnSuccessListener { result.success(true) }
            .addOnFailureListener { error ->
                stopSmsUserConsent()
                result.error("SMS_CONSENT_START_FAILED", error.message, null)
            }
    }

    private fun stopSmsUserConsent() {
        smsConsentReceiver?.let { receiver ->
            try {
                unregisterReceiver(receiver)
            } catch (_: IllegalArgumentException) {
            }
        }
        smsConsentReceiver = null
    }

    @Deprecated("Deprecated in Android framework, required by SMS User Consent API.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != SMS_CONSENT_REQUEST) return

        if (resultCode == RESULT_OK && data != null) {
            val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE).orEmpty()
            emitOtpFromMessage(message)
        }

        stopSmsUserConsent()
    }

    private fun emitOtpFromMessage(message: String): Boolean {
        val code = Regex("""\b\d{4}\b""").find(message)?.value ?: return false
        otpChannel?.invokeMethod("onOtpReceived", code)
        return true
    }

    override fun onDestroy() {
        stopSmsUserConsent()
        super.onDestroy()
    }
}
