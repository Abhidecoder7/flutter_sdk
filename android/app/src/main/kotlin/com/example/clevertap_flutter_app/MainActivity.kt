package com.example.clevertap_flutter_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import com.clevertap.android.sdk.CleverTapAPI
import com.google.firebase.messaging.Constants.MessageNotificationKeys.CHANNEL
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterFragmentActivity(){

     override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // On Android 12 and above, inform the notification click to get the pushClickedPayloadReceived callback on dart side.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val cleverTapDefaultInstance = CleverTapAPI.getDefaultInstance(this)

            cleverTapDefaultInstance?.pushNotificationClickedEvent(intent!!.extras)
        }
        
        val data: Uri? = intent.data
        if (data != null) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("onDeepLinkReceived", data.toString())
        }
    }
}