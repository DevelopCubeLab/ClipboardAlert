//
//  AppDelegate.swift
//  ClipboardLab
//
//  Created by on 2024/11/3.
//

import Foundation
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var clipboardManager: ClipboardManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 设置应用快捷操作
        application.shortcutItems = [
            UIApplicationShortcutItem(type: "com.developlab.ClipboardLab",
                                      localizedTitle: "清空剪贴板",
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: "xmark.circle"),
                                      userInfo: nil)
        ]
        print("添加 清空剪贴板 快捷操作")
        
        
        return true
    }

    // 处理快捷操作的触发
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "com.developlab.ClipboardLab" {
            // 这里只是打开应用，不处理清空剪贴板
            print("检查是否触发 是")
            completionHandler(true)
        } else {
            print("检查是否触发 否")
            completionHandler(false)
        }
        
    }
    
    
}

// 长按清空剪贴板以后 一个监听器
class ClipboardManager: ObservableObject {
    @Published var clipboardCleared: Bool = false
}

