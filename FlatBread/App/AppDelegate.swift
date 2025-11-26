//
//  AppDelegate.swift
//  FlatBread
//
//  Created by andev on 11/25/25.
//

import UIKit
import iamport_ios

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    // 외부 앱에서 인증 또는 결제 후 다시 서비스 앱으로 돌아올 때 전달되는 URL을 처리하는 메서드
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Iamport.shared.receivedURL(url)
        return true
    }
}
