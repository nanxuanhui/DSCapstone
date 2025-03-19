//
//  SettingsView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation
#if os(visionOS)
import RealityKit
#endif

// 用于全局管理字体大小的类
class FontSizeManager: ObservableObject {
    @Published var sizeMultiplier: CGFloat
    
    static let shared = FontSizeManager()
    
    init() {
        let savedIndex = UserDefaults.standard.integer(forKey: "fontSizeIndex")
        self.sizeMultiplier = Self.getMultiplier(for: savedIndex)
    }
    
    static func getMultiplier(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0.85  // 小
        case 1: return 1.0   // 中（默认）
        case 2: return 1.15  // 大
        case 3: return 1.3   // 特大
        default: return 1.0
        }
    }
    
    func updateSize(index: Int) {
        self.sizeMultiplier = Self.getMultiplier(for: index)
        UserDefaults.standard.set(index, forKey: "fontSizeIndex")
    }
}

// 扩展字体修饰符
extension View {
    func dynamicFontSize(style: Font.TextStyle) -> some View {
        self.modifier(DynamicFontSizeModifier(style: style))
    }
}

// 字体大小修饰器 - 修复版本
struct DynamicFontSizeModifier: ViewModifier {
    @ObservedObject private var fontSizeManager = FontSizeManager.shared
    let style: Font.TextStyle
    
    func body(content: Content) -> some View {
        content
            .font(getFont(for: style))
    }
    
    private func getFont(for style: Font.TextStyle) -> Font {
        // 根据字体样式和缩放比例返回合适的字体
        switch style {
        case .largeTitle:
            return .system(size: 34 * fontSizeManager.sizeMultiplier, weight: .bold)
        case .title:
            return .system(size: 28 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .title2:
            return .system(size: 22 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .title3:
            return .system(size: 20 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .headline:
            return .system(size: 17 * fontSizeManager.sizeMultiplier, weight: .semibold)
        case .body:
            return .system(size: 17 * fontSizeManager.sizeMultiplier)
        case .callout:
            return .system(size: 16 * fontSizeManager.sizeMultiplier)
        case .subheadline:
            return .system(size: 15 * fontSizeManager.sizeMultiplier)
        case .footnote:
            return .system(size: 13 * fontSizeManager.sizeMultiplier)
        case .caption:
            return .system(size: 12 * fontSizeManager.sizeMultiplier)
        case .caption2:
            return .system(size: 11 * fontSizeManager.sizeMultiplier)
        @unknown default:
            return .system(size: 17 * fontSizeManager.sizeMultiplier)
        }
    }
}

struct SettingsView: View {
    @State private var preferredColorScheme: Int = UserDefaults.standard.integer(forKey: "preferredColorScheme")
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("emergencyContactsEnabled") private var emergencyContactsEnabled: Bool = true
    @AppStorage("fontSizeIndex") private var fontSizeIndex: Int = 1 // 0:小 1:中 2:大 3:特大
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0 // 0:蓝 1:绿 2:紫 3:橙
    @AppStorage("cameraAccess") private var cameraAccess: Bool = true
    @AppStorage("microphoneAccess") private var microphoneAccess: Bool = true
    @AppStorage("locationAccess") private var locationAccess: Bool = true
    @AppStorage("dataAnalysis") private var dataAnalysis: Bool = false
    
    @ObservedObject private var fontSizeManager = FontSizeManager.shared
    
    @State private var activeColorScheme: ColorScheme? = nil
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac {
                // iPad和Vision Pro界面 - 使用简洁直观的网格布局
                simpleGridLayout
            } else {
                // iPhone界面 - 使用分组表单
                iPhoneLayout
            }
        }
        .preferredColorScheme(activeColorScheme)
        .onAppear {
            // 确保fontSizeIndex与FontSizeManager同步
            fontSizeManager.updateSize(index: fontSizeIndex)
            applyColorScheme(preferredColorScheme)
        }
    }
    
    private func applyColorScheme(_ value: Int) {
        switch value {
        case 1:  // 浅色
            activeColorScheme = .light
        case 2:  // 深色
            activeColorScheme = .dark
        default: // 系统
            activeColorScheme = nil
        }
        UserDefaults.standard.set(value, forKey: "preferredColorScheme")
    }
    
    // iPad和Vision Pro的简洁网格布局
    var simpleGridLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 页面标题
                Text("设置")
                    .dynamicFontSize(style: .largeTitle)
                    .bold()
                    .padding(.top)
                
                // 设置分组
                settingsGroupView(title: "通知设置") {
                    SimpleToggleRow(title: "允许通知", isOn: $notificationsEnabled)
                    SimpleToggleRow(title: "震动提醒", isOn: $vibrationEnabled)
                    SimpleToggleRow(title: "声音提醒", isOn: $soundEnabled)
                    SimpleToggleRow(title: "紧急联系人通知", isOn: $emergencyContactsEnabled)
                }
                
                #if !os(visionOS)
                settingsGroupView(title: "外观设置") {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("外观主题")
                            .dynamicFontSize(style: .headline)
                        
                        Picker("", selection: Binding(
                            get: { self.preferredColorScheme },
                            set: { newValue in
                                self.preferredColorScheme = newValue
                                self.applyColorScheme(newValue)
                            }
                        )) {
                            Text("系统").tag(0)
                            Text("浅色").tag(1)
                            Text("深色").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text("字体大小")
                            .dynamicFontSize(style: .headline)
                            .padding(.top, 5)
                        
                        Picker("", selection: Binding(
                            get: { self.fontSizeIndex },
                            set: { newValue in
                                self.fontSizeIndex = newValue
                                self.fontSizeManager.updateSize(index: newValue)
                            }
                        )) {
                            Text("小").tag(0)
                            Text("中").tag(1)
                            Text("大").tag(2)
                            Text("特大").tag(3)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 5)
                }
                #endif
                
                settingsGroupView(title: "隐私设置") {
                    SimpleToggleRow(title: "允许相机访问", isOn: $cameraAccess)
                    SimpleToggleRow(title: "允许麦克风访问", isOn: $microphoneAccess)
                    SimpleToggleRow(title: "允许位置访问", isOn: $locationAccess)
                    SimpleToggleRow(title: "数据分析", isOn: $dataAnalysis)
                    
                    Button(action: {}) {
                        Text("删除所有数据")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    .padding(.top, 5)
                }
                
                // 应用数据部分
                settingsGroupView(title: "应用数据") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("摔倒检测存储空间: 24.5 MB")
                            .dynamicFontSize(style: .body)
                        Text("其他缓存文件: 5.2 MB")
                            .dynamicFontSize(style: .body)
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        Text("清除缓存")
                            .dynamicFontSize(style: .body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    .padding(.top, 5)
                }
                
                // 支持部分
                settingsGroupView(title: "支持") {
                    Button(action: {}) {
                        HStack {
                            Text("帮助中心")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        HStack {
                            Text("用户手册")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        HStack {
                            Text("隐私政策")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 5)
                    
                    Button(action: {}) {
                        HStack {
                            Text("用户协议")
                                .dynamicFontSize(style: .body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 5)
                }
                
                // 版权信息
                Text("© 2025 FallDetect. 保留所有权利。")
                    .dynamicFontSize(style: .footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
    
    // iPhone布局 - 使用表单
    var iPhoneLayout: some View {
        NavigationView {
            Form {
                // 通知设置
                Section(header: Text("通知设置").dynamicFontSize(style: .footnote)) {
                    Toggle("允许通知", isOn: $notificationsEnabled)
                    Toggle("震动提醒", isOn: $vibrationEnabled)
                    Toggle("声音提醒", isOn: $soundEnabled)
                    Toggle("紧急联系人通知", isOn: $emergencyContactsEnabled)
                }
                
                // 外观设置
                Section(header: Text("外观设置").dynamicFontSize(style: .footnote)) {
                    Picker("外观主题", selection: Binding(
                        get: { self.preferredColorScheme },
                        set: { newValue in
                            self.preferredColorScheme = newValue
                            self.applyColorScheme(newValue)
                        }
                    )) {
                        Text("系统").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    }
                    
                    Picker("字体大小", selection: Binding(
                        get: { self.fontSizeIndex },
                        set: { newValue in
                            self.fontSizeIndex = newValue
                            self.fontSizeManager.updateSize(index: newValue)
                        }
                    )) {
                        Text("小").tag(0)
                        Text("中").tag(1)
                        Text("大").tag(2)
                        Text("特大").tag(3)
                    }
                }
                
                // 隐私设置
                Section(header: Text("隐私设置").dynamicFontSize(style: .footnote)) {
                    Toggle("允许相机访问", isOn: $cameraAccess)
                    Toggle("允许麦克风访问", isOn: $microphoneAccess)
                    Toggle("允许位置访问", isOn: $locationAccess)
                    Toggle("数据分析", isOn: $dataAnalysis)
                    Button("删除所有数据") {
                        // 删除数据操作
                    }
                    .foregroundColor(.red)
                }
                
                // 应用数据
                Section(header: Text("应用数据").dynamicFontSize(style: .footnote)) {
                    Text("摔倒检测存储空间: 24.5 MB")
                    Text("其他缓存文件: 5.2 MB")
                    Button("清除缓存") {
                        // 清除缓存操作
                    }
                }
                
                // 支持
                Section(header: Text("支持").dynamicFontSize(style: .footnote)) {
                    NavigationLink("帮助中心") {
                        Text("帮助内容").dynamicFontSize(style: .body)
                    }
                    
                    NavigationLink("用户手册") {
                        Text("用户指南").dynamicFontSize(style: .body)
                    }
                    
                    NavigationLink("隐私政策") {
                        Text("隐私政策内容").dynamicFontSize(style: .body)
                    }
                    
                    NavigationLink("用户协议") {
                        Text("协议内容").dynamicFontSize(style: .body)
                    }
                }
                
                // 版权
                Section {
                    Text("© 2025 FallDetect. 保留所有权利。")
                        .dynamicFontSize(style: .footnote)
                        .foregroundColor(.gray)
                }
            }
            .navigationBarTitle("设置")
        }
    }
    
    // 设置分组视图
    func settingsGroupView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .dynamicFontSize(style: .headline)
                .padding(.top, 5)
            
            VStack(spacing: 12) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

// 简洁的开关行
struct SimpleToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .dynamicFontSize(style: .body)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 3)
    }
}

// 判断是否在Vision Pro上运行的扩展
extension ProcessInfo {
    var isiOSAppOnMac: Bool {
        #if os(visionOS)
        return true
        #else
        return false
        #endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// 在相机管理器类中
class CameraManager {
    private var captureSession: AVCaptureSession?
    
    func setupCamera() {
        #if os(visionOS)
        // Vision Pro 摄像头设置
        setupVisionProCamera()
        #else
        // iOS/iPad 摄像头设置 - 仅使用后置摄像头
        setupMobileCamera()
        #endif
    }
    
    #if os(visionOS)
    private func setupVisionProCamera() {
        // Vision Pro 直接使用系统摄像头，不需要指定位置
        let session = AVCaptureSession()
        
        // 查找任何可用摄像头设备
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("无法访问摄像头")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // 配置其余会话设置...
            self.captureSession = session
        } catch {
            print("摄像头设置错误: \(error)")
        }
    }
    #else
    private func setupMobileCamera() {
        // iOS/iPad - 仅使用后置摄像头
        let session = AVCaptureSession()
        
        // 明确请求后置广角摄像头
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back // 仅指定后置摄像头
        )
        
        guard let device = deviceDiscoverySession.devices.first else {
            print("无法找到后置摄像头")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // 配置其余会话设置...
            self.captureSession = session
        } catch {
            print("摄像头设置错误: \(error)")
        }
    }
    #endif
    
    // 其余摄像头管理方法...
} 