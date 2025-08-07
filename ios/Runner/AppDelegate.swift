//import Flutter
//import UIKit
//import FacebookCore
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}


import UIKit
import Flutter
import FBSDKShareKit // 1. Facebook SDK를 사용하려면 import해야 합니다.
import Foundation
import KakaoSDKShare
import KakaoSDKTemplate
import KakaoSDKCommon

@main
@objc class AppDelegate: FlutterAppDelegate, SharingDelegate { // 2. SharingDelegate 프로토콜 추가
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let socialShareChannel = FlutterMethodChannel(name: "com.oboa.chat/social_share", binaryMessenger: controller.binaryMessenger)

    socialShareChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "shareLinkContent" else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      if let args = call.arguments as? [String: Any],
         let contentUrlString = args["contentUrl"] as? String {
        
        // 3. iOS 공유 로직 추가
        guard let url = URL(string: contentUrlString) else {
          result(FlutterError(code: "INVALID_URL", message: "URL is invalid", details: nil))
          return
        }
        
        let content = ShareLinkContent()
        content.contentURL = url
        
        let dialog = ShareDialog(
          viewController: controller, // 이 부분이 중요합니다. FlutterViewController를 전달합니다.
          content: content,
          delegate: self
        )
        
        if dialog.canShow {
          dialog.show()
          result("Share dialog showed") // 다이얼로그 표시 성공 시 바로 리턴
        } else {
           result(FlutterError(code: "FACEBOOK_APP_NOT_INSTALLED", message: "Facebook app is not installed.", details: nil))
        }

      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments not valid", details: nil))
      }
    })
      
    KakaoSDK.initSDK(appKey: "1290150")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - SharingDelegate
  // 4. SharingDelegate 프로토콜 메소드 구현
  func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
      // 공유 완료 시 호출되는 로직. 필요에 따라 구현
  }

  func sharer(_ sharer: Sharing, didFailWithError error: Error) {
      // 공유 실패 시 호출되는 로직. 필요에 따라 구현
  }

  func sharerDidCancel(_ sharer: Sharing) {
      // 공유 취소 시 호출되는 로직. 필요에 따라 구현
  }
}
