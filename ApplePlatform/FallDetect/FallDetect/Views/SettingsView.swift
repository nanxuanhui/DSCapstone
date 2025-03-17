//
//  SettingsView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @AppStorage("fallDetectionSensitivity") private var sensitivity = 0.7
    @AppStorage("autoEmergencyCall") private var autoEmergencyCall = false
    @AppStorage("emergencyContact") private var emergencyContact = ""
    @AppStorage("emergencyMessage") private var emergencyMessage = "需要帮助！我可能摔倒了。"
    @AppStorage("automaticBackup") private var automaticBackup = true
    
    @Environment(\.modelContext) private var modelContext
    @State private var showBackupOptions = false
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("摔倒检测设置")) {
                    VStack {
                        Text("检测灵敏度: \(Int(sensitivity * 100))%")
                        Slider(value: $sensitivity, in: 0.5...0.95)
                    }
                    
                    Toggle("检测到摔倒时自动拨打紧急电话", isOn: $autoEmergencyCall)
                }
                
                Section(header: Text("紧急联系人")) {
                    TextField("紧急联系人号码", text: $emergencyContact)
                        .keyboardType(.phonePad)
                    
                    TextField("紧急消息", text: $emergencyMessage)
                }
                
                Section(header: Text("数据备份")) {
                    Toggle("启用自动备份提醒", isOn: $automaticBackup)
                        .onChange(of: automaticBackup) { _, newValue in
                            if newValue {
                                BackupManager.shared.scheduleAutomaticBackup()
                            } else {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["backupReminder"])
                            }
                        }
                    
                    Button("备份数据") {
                        showBackupOptions = true
                    }
                    
                    Button("重置所有数据") {
                        showResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("模型设置")) {
                    NavigationLink(destination: ModelSettingsView()) {
                        Text("模型设置")
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Button("隐私政策") {
                        // 打开隐私政策
                        if let url = URL(string: "https://www.example.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .actionSheet(isPresented: $showBackupOptions) {
                ActionSheet(
                    title: Text("选择备份方式"),
                    message: Text("如何备份您的数据?"),
                    buttons: [
                        .default(Text("导出数据 (JSON)")) {
                            exportData()
                        },
                        .default(Text("完整备份 (包含图像和音频)")) {
                            fullBackup()
                        },
                        .cancel()
                    ]
                )
            }
            .alert("确认重置", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) {}
                Button("重置", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("所有数据将被永久删除。此操作无法撤销。")
            }
        }
    }
    
    private func exportData() {
        let items = DatabaseManager.shared.fetchRecords(type: nil, in: modelContext)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            BackupManager.shared.shareData(items: items, from: rootViewController)
        }
    }
    
    private func fullBackup() {
        let items = DatabaseManager.shared.fetchRecords(type: nil, in: modelContext)
        
        if let zipURL = BackupManager.shared.createFullBackup(items: items),
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            let activityVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func resetAllData() {
        DatabaseManager.shared.deleteAllRecords(in: modelContext)
    }
}

struct ModelSettingsView: View {
    @AppStorage("useFallModel") private var useFallModel = true
    @AppStorage("useEmotionModel") private var useEmotionModel = true
    @State private var showFallModelImport = false
    @State private var showEmotionModelImport = false
    
    var body: some View {
        Form {
            Section(header: Text("YOLOv5 摔倒检测模型")) {
                Toggle("启用摔倒检测", isOn: $useFallModel)
                
                Button("重新加载模型") {
                    FallDetectionManager.shared.reloadModel()
                }
                .disabled(!useFallModel)
                
                Button("导入新模型") {
                    showFallModelImport = true
                }
                .disabled(!useFallModel)
            }
            
            Section(header: Text("情绪检测模型")) {
                Toggle("启用情绪检测", isOn: $useEmotionModel)
                
                Button("重新加载模型") {
                    EmotionDetectionManager.shared.reloadModel()
                }
                .disabled(!useEmotionModel)
                
                Button("导入新模型") {
                    showEmotionModelImport = true
                }
                .disabled(!useEmotionModel)
            }
        }
        .navigationTitle("模型设置")
        .fileImporter(
            isPresented: $showFallModelImport,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            // 处理摔倒检测模型导入
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                print("导入摔倒检测模型: \(url.path)")
                // 这里需要实现模型文件复制和加载逻辑
            case .failure(let error):
                print("模型导入失败: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showEmotionModelImport,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            // 处理情绪检测模型导入
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                print("导入情绪检测模型: \(url.path)")
                // 这里需要实现模型文件复制和加载逻辑
            case .failure(let error):
                print("模型导入失败: \(error.localizedDescription)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 