//
//  ContentView.swift
//  ClipboardLab
//
//  Created by on 2024/11/3.
//

import SwiftUI

struct ContentView: View {
    
    let systemVersion = UIDevice.current.systemVersion
    @State private var pastedText: String = ""
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack {
            if let version = Double(systemVersion), version < 16.0 {
                // 系统版本低于16.0
                Text("您当前的系统版本为iOS \(systemVersion) \n您可以尝试使用该工具进行测试。")
                    .foregroundColor(.green)
                    .padding()
            } else {
                // 系统版本为16.0及以上
                Text("您当前的系统版本为iOS \(systemVersion) \n系统已包含此功能，无需注入插件，您无需使用此工具进行测试。")
                    .foregroundColor(.orange)
                    .padding()
            }
            
            TextField("粘贴内容会显示在这里", text: $pastedText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: 300)
            
            Button(action: {
                // 获取剪贴板的内容，并赋值给pastedText
                if let clipboardContent = UIPasteboard.general.string {
                    pastedText = clipboardContent
                } else {
                    pastedText = "剪贴板为空"
                }}) {
                    Text("粘贴")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            
            Button(action: {
                clearClipboard()
            }) {
                Text("清空剪贴板")
                    .font(.headline)
                    .padding(20)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if clipboardManager.clipboardCleared {
                Text("剪贴板已清空")
                    .foregroundColor(.red)
                    .padding()
            }
            
        }
        .padding()
        .onAppear() {
            checkClipboardStatus()
        }
        
    
    }
    
    private func clearClipboard() {
        UIPasteboard.general.string = nil
        clipboardManager.clipboardCleared = true
        pastedText = "剪贴板已清空"
    }
    
    private func checkClipboardStatus() {
        // 如果需要在打开应用时检查剪贴板状态，可以在这里添加逻辑
        // 例如，如果想要清空状态在打开时显示，可以在此进行设置
        clipboardManager.clipboardCleared = false
    }
    
    
}

#Preview {
    ContentView()
}
