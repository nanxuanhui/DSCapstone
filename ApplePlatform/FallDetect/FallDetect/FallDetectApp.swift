//
//  FallDetectApp.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData

@main
struct FallDetectApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: RecordItem.self)
                #if os(visionOS)
                .preferredColorScheme(.light) // 为Vision Pro强制使用浅色模式
                #endif
        }
    }
}
