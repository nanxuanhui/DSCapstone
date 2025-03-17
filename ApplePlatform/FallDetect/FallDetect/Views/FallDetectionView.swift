//
//  FallDetectionView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import AVFoundation
import Vision

struct FallDetectionView: View {
    @StateObject private var viewModel = FallDetectionViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        PlatformAdaptiveView {
            // 普通iOS设备视图
            ZStack {
                // 相机预览层
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
                
                // 顶部状态栏
                VStack {
                    HStack {
                        Button(action: {
                            viewModel.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        if viewModel.isDetecting {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                
                                Text("检测中")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 录制按钮
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleDetection()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.isDetecting ? Color.red : Color.white)
                                    .frame(width: 70, height: 70)
                                
                                if viewModel.isDetecting {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 80, height: 80)
                                }
                            }
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 40)
                    }
                }
                
                // 摔倒警告覆盖层
                if viewModel.fallDetected {
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("检测到摔倒!")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("是否需要紧急联系人帮助?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 30) {
                                    Button("取消警报") {
                                        viewModel.cancelFallAlert()
                                    }
                                    .padding()
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    
                                    Button("请求帮助") {
                                        viewModel.requestHelp()
                                        saveFallEvent()
                                    }
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(30)
                            .frame(width: geometry.size.width * 0.9)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(20)
                            
                            Spacer()
                        }
                        .frame(width: geometry.size.width)
                        .background(Color.red.opacity(0.3))
                    }
                }
            }
            .onAppear {
                viewModel.setupCamera()
            }
        } visionContent: {
            // Vision Pro 特定视图
            VStack {
                Text("摔倒检测 - Vision Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.1))
                    
                    VStack(spacing: 30) {
                        HStack {
                            Spacer()
                            
                            VStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 40))
                                Text("相机预览")
                            }
                            .frame(width: 340, height: 300)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(16)
                            
                            Spacer()
                        }
                        
                        Button(action: {
                            viewModel.toggleDetection()
                        }) {
                            Label(
                                viewModel.isDetecting ? "停止检测" : "开始检测",
                                systemImage: viewModel.isDetecting ? "stop.fill" : "play.fill"
                            )
                            .font(.headline)
                            .padding()
                            .frame(width: 200)
                            .background(viewModel.isDetecting ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .frame(height: 400)
                .padding()
                
                // 状态面板
                VStack(alignment: .leading, spacing: 16) {
                    Text("检测状态:")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(viewModel.isDetecting ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(viewModel.isDetecting ? "正在监测" : "未监测")
                            .foregroundColor(viewModel.isDetecting ? .primary : .secondary)
                    }
                    
                    if viewModel.fallDetected {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text("已检测到摔倒！")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                            
                            Button("请求帮助") {
                                viewModel.requestHelp()
                                saveFallEvent()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("取消警报") {
                                viewModel.cancelFallAlert()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                .padding()
            }
            .onAppear {
                viewModel.setupVisionProCamera()
            }
        }
    }
    
    private func saveFallEvent() {
        if let captureImage = FallDetectionManager.shared.captureFrame(from: viewModel.session),
           let imageData = captureImage.jpegData(compressionQuality: 0.8) {
            
            DatabaseManager.shared.saveFallDetectionRecord(
                in: modelContext,
                imageData: imageData,
                confidenceScore: viewModel.fallConfidence,
                details: "检测到严重摔倒事件",
                helpRequested: true,
                severity: viewModel.fallConfidence > 0.8 ? "严重" : "中度",
                actionTaken: "已请求帮助"
            )
        }
    }
}

struct PlatformAdaptiveView<IOSContent: View, VisionContent: View>: View {
    var iosContent: () -> IOSContent
    var visionContent: () -> VisionContent
    
    init(@ViewBuilder iosContent: @escaping () -> IOSContent,
         @ViewBuilder visionContent: @escaping () -> VisionContent) {
        self.iosContent = iosContent
        self.visionContent = visionContent
    }
    
    var body: some View {
        #if os(visionOS)
        visionContent()
        #else
        iosContent()
        #endif
    }
}

// 相机预览视图
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// 视图模型
class FallDetectionViewModel: NSObject, ObservableObject {
    @Published var isDetecting = false
    @Published var fallDetected = false
    @Published var fallConfidence: Double = 0.0
    @Published var session = AVCaptureSession()
    
    private var captureDevice: AVCaptureDevice?
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var isUsingFrontCamera = false
    
    @AppStorage("autoEmergencyCall") private var autoEmergencyCall = false
    @AppStorage("emergencyContact") private var emergencyContact = ""
    
    func setupCamera() {
        checkCameraPermission { granted in
            guard granted else { return }
            
            self.sessionQueue.async {
                self.configureCaptureSession()
            }
        }
    }
    
    func setupVisionProCamera() {
        // Vision Pro相机设置，因为Vision Pro使用不同的相机API
        #if os(visionOS)
        print("设置Vision Pro相机")
        // 在Vision Pro上，可能使用ARKit或其他框架来访问空间相机
        // 这里简化为一个模拟，实际应用需要使用正确的API
        self.simulateDetection()
        #endif
    }
    
    #if os(visionOS)
    private func simulateDetection() {
        // 模拟Vision Pro上的检测过程
        if self.isDetecting {
            // 每10秒随机模拟一次摔倒检测
            DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) { [weak self] in
                guard let self = self, self.isDetecting else { return }
                
                let shouldDetectFall = Bool.random()
                if shouldDetectFall {
                    DispatchQueue.main.async {
                        self.fallDetected = true
                        self.fallConfidence = Double.random(in: 0.75...0.95)
                    }
                }
                
                // 继续模拟
                self.simulateDetection()
            }
        }
    }
    #endif
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
    
    func configureCaptureSession() {
        session.beginConfiguration()
        
        // 添加输入设备
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }
        
        captureDevice = videoDevice
        session.addInput(videoInput)
        
        // 配置输出
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        // 启动预览
        DispatchQueue.main.async {
            self.session.startRunning()
        }
    }
    
    func switchCamera() {
        sessionQueue.async {
            self.session.beginConfiguration()
            
            // 移除当前输入
            if let currentInput = self.session.inputs.first {
                self.session.removeInput(currentInput)
            }
            
            // 切换相机
            let position: AVCaptureDevice.Position = self.isUsingFrontCamera ? .back : .front
            
            if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let newInput = try? AVCaptureDeviceInput(device: newCamera),
               self.session.canAddInput(newInput) {
                
                self.captureDevice = newCamera
                self.session.addInput(newInput)
                self.isUsingFrontCamera.toggle()
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func toggleDetection() {
        isDetecting.toggle()
        
        #if os(visionOS)
        if isDetecting {
            simulateDetection()
        }
        #endif
    }
    
    func cancelFallAlert() {
        fallDetected = false
    }
    
    func requestHelp() {
        fallDetected = false
        
        // 检查是否启用自动紧急呼叫
        if autoEmergencyCall && !emergencyContact.isEmpty {
            // 格式化电话号码并拨打电话
            let formattedNumber = emergencyContact.replacingOccurrences(of: " ", with: "")
            #if !os(visionOS)
            if let url = URL(string: "tel://\(formattedNumber)") {
                UIApplication.shared.open(url)
            }
            #else
            print("Vision Pro上模拟拨打电话到: \(formattedNumber)")
            #endif
        }
    }
}

// 视频帧处理
extension FallDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isDetecting, !fallDetected, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 执行摔倒检测
        FallDetectionManager.shared.processFrame(pixelBuffer) { [weak self] detected, confidence in
            guard let self = self, detected else { return }
            
            DispatchQueue.main.async {
                self.fallDetected = true
                self.fallConfidence = confidence
            }
        }
    }
}

// 其他需要的视图和助手类...