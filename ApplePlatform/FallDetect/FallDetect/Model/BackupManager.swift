//
//  BackupManager.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import Foundation
import SwiftData
import UIKit
import UserNotifications
import SwiftUI

class BackupManager {
    static let shared = BackupManager()
    
    private init() {}
    
    // 导出数据库为JSON
    func exportDataToJSON(items: [RecordItem]) -> Data? {
        let itemsExport = items.map { item -> [String: Any] in
            var itemDict: [String: Any] = [
                "id": item.id.uuidString,
                "timestamp": item.timestamp.timeIntervalSince1970,
                "type": item.type
            ]
            
            if let details = item.details {
                itemDict["details"] = details
            }
            
            if let confidenceScore = item.confidenceScore {
                itemDict["confidenceScore"] = confidenceScore
            }
            
            if let location = item.location {
                itemDict["location"] = location
            }
            
            if let fallSeverity = item.fallSeverity {
                itemDict["fallSeverity"] = fallSeverity
            }
            
            if let actionTaken = item.actionTaken {
                itemDict["actionTaken"] = actionTaken
            }
            
            itemDict["helpRequested"] = item.helpRequested
            
            // 图片数据不包含在JSON中，只包含它们的存在状态
            itemDict["hasImageData"] = item.imageData != nil
            
            return itemDict
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: itemsExport, options: .prettyPrinted)
            return jsonData
        } catch {
            print("导出为JSON失败: \(error)")
            return nil
        }
    }
    
    // 分享数据
    func shareData(items: [RecordItem], from viewController: UIViewController) {
        guard let jsonData = exportDataToJSON(items: items),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "FallDetect_Export_\(Date().timeIntervalSince1970).json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // 分享文件
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            viewController.present(activityVC, animated: true)
        } catch {
            print("创建导出文件失败: \(error)")
        }
    }
    
    // 定期备份
    func scheduleAutomaticBackup() {
        // 设置每周自动备份
        let notificationCenter = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "数据备份提醒"
        content.body = "请备份您的摔倒检测数据"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // 周日
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "backupReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("设置备份提醒失败: \(error)")
            }
        }
    }
    
    // 创建ZIP备份（包含图片）
    func createFullBackup(items: [RecordItem]) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let backupDir = tempDir.appendingPathComponent("FallDetectBackup_\(Date().timeIntervalSince1970)")
        
        do {
            try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
            
            // 保存元数据
            if let jsonData = exportDataToJSON(items: items) {
                let metadataURL = backupDir.appendingPathComponent("metadata.json")
                try jsonData.write(to: metadataURL)
            }
            
            // 保存图片数据
            for item in items {
                if let imageData = item.imageData {
                    let imageURL = backupDir.appendingPathComponent("image_\(item.id.uuidString).jpg")
                    try imageData.write(to: imageURL)
                }
            }
            
            // 在实际应用中，这里需要使用ZIP压缩库
            // 现在简单返回文件夹URL
            return backupDir
        } catch {
            print("创建完整备份失败: \(error)")
            return nil
        }
    }
}

// SwiftUI视图扩展以获取UIViewController
extension View {
    func getUIViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.rootViewController
    }
} 