package com.oboa.chat

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import com.facebook.FacebookSdk
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.share.Sharer
import com.facebook.share.model.ShareLinkContent
import com.facebook.share.widget.ShareDialog
import androidx.core.net.toUri

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.oboa.chat/social_share"
    private lateinit var callbackManager: CallbackManager
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FacebookSdk.sdkInitialize(this.applicationContext)
        callbackManager = CallbackManager.Factory.create()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        callbackManager?.onActivityResult(requestCode, resultCode, data)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "shareLinkContent") {
                pendingResult = result // 결과 객체를 저장하여 나중에 사용

                val contentUrl = call.argument<String>("contentUrl")
                val shareDialog = ShareDialog(this)
                val linkContent = ShareLinkContent.Builder()
                    .setContentUrl(contentUrl?.toUri())
                    .build()

                if (ShareDialog.canShow(ShareLinkContent::class.java)) {
                    shareDialog.registerCallback(callbackManager, object : FacebookCallback<Sharer.Result> {
                        override fun onSuccess(shareResult: Sharer.Result) {
                            // 공유 성공 시
                            pendingResult?.success("Share Success")
                            pendingResult = null
                        }

                        override fun onCancel() {
                            // 공유 취소 시
                            pendingResult?.success("Share Cancelled")
                            pendingResult = null
                        }

                        override fun onError(error: FacebookException) {
                            // 공유 실패 시
                            pendingResult?.error("SHARE_ERROR", error.message, null)
                            pendingResult = null
                        }
                    })
                    shareDialog.show(linkContent)
                } else {
                    pendingResult?.error("FACEBOOK_NOT_INSTALLED", "Facebook app is not installed.", null)
                    pendingResult = null
                }
            } else {
                result.notImplemented()
            }
        }
    }
}