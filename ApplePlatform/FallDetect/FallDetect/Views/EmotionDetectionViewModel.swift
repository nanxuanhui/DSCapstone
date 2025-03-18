import AVFoundation
import Speech
import SwiftUI

final class EmotionDetectionViewModel: ObservableObject {
    // 音频处理相关
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioSession: AVAudioSession?
    
    // 状态相关
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var emotion = "未检测"
    @Published var confidenceScore: Double = 0.0
    @Published var errorMessage: String?
    
    // 初始化
    init() {
        setupAudioSession()
    }
    
    // 安全地设置音频会话
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession?.setActive(false)
        } catch {
            print("音频会话初始化错误: \(error.localizedDescription)")
        }
    }
    
    // 开始录音
    func startRecording() {
        // 添加调试日志
        print("开始录音...")
        
        // 安全检查 - 避免重复启动
        guard !isRecording else {
            print("已经在录音中，忽略请求")
            return 
        }
        
        // 重置错误信息
        errorMessage = nil
        isProcessing = true
        
        // 检查麦克风权限
        checkMicrophonePermission { [weak self] permissionGranted in
            guard let self = self, permissionGranted else {
                print("麦克风权限被拒绝")
                DispatchQueue.main.async {
                    self?.errorMessage = "需要麦克风访问权限，请在设置中允许访问"
                    self?.isProcessing = false
                }
                return
            }
            
            print("麦克风权限已授予，检查语音识别权限...")
            
            // 检查语音识别权限
            self.checkSpeechRecognitionPermission { permissionGranted in
                guard permissionGranted else {
                    print("语音识别权限被拒绝")
                    DispatchQueue.main.async {
                        self.errorMessage = "需要语音识别权限，请在设置中允许访问"
                        self.isProcessing = false
                    }
                    return
                }
                
                print("语音识别权限已授予，初始化音频录制...")
                
                // 启动录音
                self.initializeAudioRecording()
            }
        }
    }
    
    // 检查麦克风权限
    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            DispatchQueue.main.async {
                self.errorMessage = "麦克风权限被拒绝"
            }
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        @unknown default:
            completion(false)
        }
    }
    
    // 检查语音识别权限
    private func checkSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            let granted = status == .authorized
            if !granted {
                DispatchQueue.main.async {
                    self.errorMessage = "语音识别权限不可用"
                }
            }
            completion(granted)
        }
    }
    
    // 初始化音频录制
    private func initializeAudioRecording() {
        // 停止任何现有的录音
        safelyStopRecording()
        
        print("创建新的音频引擎...")
        
        // 创建新的音频组件
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 安全检查
        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            print("语音识别组件不可用")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "语音识别组件不可用，请检查设备设置"
                self?.isProcessing = false
            }
            return
        }
        
        // 配置识别请求
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        do {
            print("激活音频会话...")
            
            // 激活音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("获取输入节点...")
            
            // 获取输入节点
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            print("准备音频引擎...")
            
            // 准备引擎
            audioEngine.prepare()
            
            print("安装音频Tap...")
            
            // 安全移除任何现有tap
            do {
                inputNode.removeTap(onBus: 0)
            } catch {
                print("移除现有tap时出错（可忽略）：\(error.localizedDescription)")
            }
            
            // 安装新tap
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            print("启动音频引擎...")
            
            // 启动引擎
            try audioEngine.start()
            
            print("启动识别任务...")
            
            // 启动识别任务
            startRecognitionTask()
            
            print("成功启动录音!")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isRecording = true
                self.isProcessing = false
            }
        } catch {
            print("音频引擎启动失败: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "音频引擎启动失败: \(error.localizedDescription)"
                self.isProcessing = false
                self.safelyStopRecording()
            }
        }
    }
    
    // 开始识别任务
    private func startRecognitionTask() {
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else { return }
        
        // 创建识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // 更新转录文本
                let transcription = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                DispatchQueue.main.async {
                    self.transcribedText = transcription
                    
                    // 如果有足够的文本，分析情绪
                    if transcription.count > 3 {
                        self.analyzeEmotion(transcription) { emotion, score in
                            DispatchQueue.main.async {
                                self.emotion = emotion
                                self.confidenceScore = score
                            }
                        }
                    }
                }
            }
            
            // 处理错误
            if let error = error {
                print("识别错误: \(error.localizedDescription)")
                
                // 检查是否是可恢复的错误
                let nsError = error as NSError
                if nsError.domain == "kAFAssistantErrorDomain" && 
                   nsError.code == 203 {
                    // 网络暂时性错误，可以继续
                    return
                }
                
                DispatchQueue.main.async {
                    self.safelyStopRecording()
                }
            }
            
            // 如果识别结束，重新开始
            if isFinal {
                DispatchQueue.main.async {
                    guard self.isRecording else { return }
                    
                    // 结束当前任务并开始新任务
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                    
                    // 重新开始识别
                    self.initializeAudioRecording()
                }
            }
        }
    }
    
    // 分析情绪
    func analyzeEmotion(_ text: String, completion: @escaping (String, Double) -> Void) {
        // 这里是您的情绪分析代码，可以调用API或使用本地模型
        // 简单示例：
        let emotions = ["高兴", "悲伤", "愤怒", "焦虑", "平静", "惊讶"]
        let emotion = emotions.randomElement() ?? "未知"
        let score = Double.random(in: 0.65...0.95)
        
        // 延迟模拟分析过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(emotion, score)
        }
    }
    
    // 安全停止录音
    func stopRecording() {
        isProcessing = true
        safelyStopRecording()
        isProcessing = false
    }
    
    // 安全清理资源
    private func safelyStopRecording() {
        // 停止音频引擎
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            do {
                audioEngine.inputNode.removeTap(onBus: 0)
            } catch {
                print("移除tap出错: \(error.localizedDescription)")
            }
        }
        
        // 取消识别任务
        recognitionTask?.cancel()
        
        // 释放资源
        recognitionTask = nil
        recognitionRequest = nil
        
        // 停用音频会话
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("音频会话停用失败: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    // 清理资源
    deinit {
        safelyStopRecording()
    }
}