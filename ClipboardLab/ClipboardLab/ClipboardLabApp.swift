//
//  ClipboardLabApp.swift
//  ClipboardLab
//
//  Created by on 2024/11/3.
//

import SwiftUI

@main
struct ClipboardLabApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var clipboardManager = ClipboardManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
        }
    }
}


