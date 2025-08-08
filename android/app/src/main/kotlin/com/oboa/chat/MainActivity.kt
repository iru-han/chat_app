package com.oboa.chat

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.net.toUri
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.share.Sharer
import com.facebook.share.model.ShareLinkContent
import com.facebook.share.widget.ShareDialog

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.oboa.chat/social_share"
    private lateinit var callbackManager: CallbackManager
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FacebookSdk.sdkInitialize() 제거 (자동 초기화)
        callbackManager = CallbackManager.Factory.create()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        callbackManager.onActivityResult(requestCode, resultCode, data)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareLinkContent") {
                pendingResult = result

                val contentUrl = call.argument<String>("contentUrl")
                val uri = contentUrl?.toUri() ?: run {
                    pendingResult?.error("INVALID_URL", "Content URL is null", null)
                    pendingResult = null
                    return@setMethodCallHandler
                }

                val shareDialog = ShareDialog(this)
                val linkContent = ShareLinkContent.Builder()
                    .setContentUrl(uri)
                    .build()

                shareDialog.registerCallback(callbackManager, object : FacebookCallback<Sharer.Result> {
                    override fun onSuccess(shareResult: Sharer.Result) {
                        pendingResult?.success("Share Success")
                        pendingResult = null
                    }

                    override fun onCancel() {
                        pendingResult?.success("Share Cancelled")
                        pendingResult = null
                    }

                    override fun onError(error: FacebookException) {
                        pendingResult?.error("SHARE_ERROR", error.message, null)
                        pendingResult = null
                    }
                })

                shareDialog.show(linkContent)

            } else {
                result.notImplemented()
            }
        }
    }
}
