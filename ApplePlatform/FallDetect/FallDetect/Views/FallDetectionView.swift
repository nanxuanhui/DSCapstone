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
                
                // 姿态检测覆盖层
                if viewModel.showPoseOverlay {
                    GeometryReader { geometry in
                        PoseOverlayView(
                            pose: viewModel.currentPose,
                            viewSize: geometry.size
                        )
                    }
                    .allowsHitTesting(false) // 允许点击穿透
                }
                
                // 顶部状态栏
                VStack {
                    HStack {
                        // 切换姿态覆盖层按钮
                        Button(action: {
                            viewModel.togglePoseOverlay()
                        }) {
                            Image(systemName: viewModel.showPoseOverlay ? "figure.walk.circle.fill" : "figure.walk.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(8)
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
                                    .fill(viewModel.isDetecting ? Color.red : Color.blue)
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
                        
                        // 姿态覆盖层切换按钮
                        Button(action: {
                            viewModel.togglePoseOverlay()
                        }) {
                            Label(
                                viewModel.showPoseOverlay ? "隐藏姿态检测" : "显示姿态检测",
                                systemImage: viewModel.showPoseOverlay ? "figure.walk.circle.fill" : "figure.walk.circle"
                            )
                            .font(.headline)
                            .padding()
                            .frame(width: 200)
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
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

// 其他需要的视图和助手类...
