//
//  EmotionDetectionView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import Speech
import SwiftData

enum AnalysisMode {
    case voice, text
}

struct EmotionDetectionView: View {
    @StateObject private var viewModel = EmotionViewModel()
    @State private var inputText = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone 布局
                compactLayout
            } else {
                // iPad/Vision Pro 布局
                wideLayout
            }
        }
        .navigationTitle("情绪分析")
    }
    
    var compactLayout: some View {
        VStack(spacing: 20) {
            // 标题和模式选择
            Text("情绪分析")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Picker("分析模式", selection: $viewModel.analysisMode) {
                Text("语音").tag(AnalysisMode.voice)
                Text("文字").tag(AnalysisMode.text)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 50)
            
            // 主要内容区域
            ScrollView {
                if viewModel.analysisMode == .voice {
                    VoiceAnalysisSection(viewModel: viewModel, modelContext: modelContext)
                } else {
                    TextAnalysisSection(inputText: $inputText, viewModel: viewModel, modelContext: modelContext)
                }
                
                // 分析结果显示
                if !viewModel.detectedEmotion.isEmpty {
                    EmotionResultCard(emotion: viewModel.detectedEmotion, 
                                     confidence: viewModel.confidenceScore,
                                     text: viewModel.analysisMode == .voice ? viewModel.transcribedText : inputText)
                        .padding()
                        .animation(.spring(), value: viewModel.detectedEmotion)
                }
            }
            .padding()
        }
    }
    
    var wideLayout: some View {
        HStack(spacing: 0) {
            // 左侧面板 - 控制区
            VStack {
                Text("分析模式")
                    .font(.headline)
                    .padding(.top)
                
                Picker("分析模式", selection: $viewModel.analysisMode) {
                    Text("语音分析").tag(AnalysisMode.voice)
                    Text("文本分析").tag(AnalysisMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                if viewModel.analysisMode == .voice {
                    // 语音分析控制
                    VStack(spacing: 25) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                                .frame(width: 160, height: 160)
                            
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.blue)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            if viewModel.isRecording {
                                viewModel.stopRecording()
                            } else {
                                viewModel.startRecording { emotion, confidence in
                                    DatabaseManager.shared.saveEmotionAnalysisRecord(
                                        in: modelContext,
                                        emotionType: emotion,
                                        confidenceScore: confidence,
                                        fullText: viewModel.transcribedText
                                    )
                                }
                            }
                        }
                        
                        Text(viewModel.isRecording ? "停止录音" : "开始录音")
                            .font(.headline)
                            .foregroundColor(viewModel.isRecording ? .red : .primary)
                    }
                    .padding(.top, 20)
                } else {
                    // 文本分析控制
                    VStack(spacing: 20) {
                        Text("文本输入")
                            .font(.headline)
                        
                        TextEditor(text: $inputText)
                            .frame(height: 200)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("\(inputText.count) 字符")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            viewModel.analyzeText(inputText) { emotion, confidence in
                                DatabaseManager.shared.saveEmotionAnalysisRecord(
                                    in: modelContext,
                                    emotionType: emotion,
                                    confidenceScore: confidence,
                                    fullText: inputText
                                )
                            }
                        }) {
                            Text("分析情绪")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(width: 200)
                                .background(inputText.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .frame(width: 350)
            .background(Color(.secondarySystemBackground))
            
            // 右侧面板 - 结果区
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.analysisMode == .voice && !viewModel.transcribedText.isEmpty {
                            // 语音识别结果
                            VStack(alignment: .leading, spacing: 10) {
                                Text("识别内容:")
                                    .font(.headline)
                                
                                Text(viewModel.transcribedText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        
                        // 情绪分析结果
                        if !viewModel.detectedEmotion.isEmpty {
                            EmotionResultCard(
                                emotion: viewModel.detectedEmotion,
                                confidence: viewModel.confidenceScore,
                                text: viewModel.analysisMode == .voice ? viewModel.transcribedText : inputText
                            )
                            .padding()
                        } else {
                            // 空状态
                            VStack(spacing: 20) {
                                Image(systemName: "square.text.square")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                Text(viewModel.analysisMode == .voice ? 
                                     "请点击左侧录音按钮开始语音分析" : 
                                     "请在左侧输入文字并点击分析按钮")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                            }
                            .padding(40)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
        }
        #if os(visionOS)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Picker("分析模式", selection: $viewModel.analysisMode) {
                    Text("语音分析").tag(AnalysisMode.voice)
                    Text("文本分析").tag(AnalysisMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
        }
        #endif
    }
}

struct VoiceAnalysisSection: View {
    let viewModel: EmotionViewModel
    let modelContext: ModelContext
    
    var body: some View {
        VStack(spacing: 25) {
            // 录音状态指示器
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(viewModel.isRecording ? Color.red : Color.blue)
                    .frame(width: 150, height: 150)
                
                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording { emotion, confidence in
                        DatabaseManager.shared.saveEmotionAnalysisRecord(
                            in: modelContext,
                            emotionType: emotion,
                            confidenceScore: confidence,
                            fullText: viewModel.transcribedText
                        )
                    }
                }
            }
            
            Text(viewModel.isRecording ? "点击停止录音" : "点击开始录音")
                .font(.headline)
                .foregroundColor(viewModel.isRecording ? .red : .primary)
            
            if viewModel.isRecording {
                // 波形图显示
                WaveformView()
                    .frame(height: 60)
                    .padding(.horizontal)
            }
            
            if !viewModel.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("识别内容:")
                        .font(.headline)
                    
                    Text(viewModel.transcribedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

struct TextAnalysisSection: View {
    @Binding var inputText: String
    let viewModel: EmotionViewModel
    let modelContext: ModelContext
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("输入文本进行情绪分析:")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(height: 200)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text("\(inputText.count) 字符")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                viewModel.analyzeText(inputText) { emotion, confidence in
                    DatabaseManager.shared.saveEmotionAnalysisRecord(
                        in: modelContext,
                        emotionType: emotion,
                        confidenceScore: confidence,
                        fullText: inputText
                    )
                }
            }) {
                Text("分析情绪")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(width: 200)
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(inputText.isEmpty)
        }
        .padding()
    }
}

struct EmotionResultCard: View {
    let emotion: String
    let confidence: Double
    let text: String
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                EmotionIcon(emotion: emotion)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading) {
                    Text("检测到情绪:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(emotion)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack {
                    Text("置信度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(confidence > 0.7 ? .green : .orange)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("内容摘要:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(text)
                    .lineLimit(3)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct EmotionIcon: View {
    let emotion: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(emotionColor.opacity(0.2))
                .frame(width: 60, height: 60)
            
            Image(systemName: emotionSymbol)
                .font(.system(size: 30))
                .foregroundColor(emotionColor)
        }
    }
    
    var emotionSymbol: String {
        switch emotion.lowercased() {
        case "开心", "高兴", "happy":
            return "face.smiling"
        case "悲伤", "sad":
            return "face.sad"
        case "愤怒", "angry":
            return "face.frownfill"
        case "惊讶", "surprised":
            return "exclamationmark.circle"
        case "恐惧", "fear":
            return "eye.trianglebadge.exclamationmark"
        case "中性", "neutral":
            return "face.dashed"
        default:
            return "questionmark.circle"
        }
    }
    
    var emotionColor: Color {
        switch emotion.lowercased() {
        case "开心", "高兴", "happy":
            return .yellow
        case "悲伤", "sad":
            return .blue
        case "愤怒", "angry":
            return .red
        case "惊讶", "surprised":
            return .purple
        case "恐惧", "fear":
            return .gray
        case "中性", "neutral":
            return .green
        default:
            return .secondary
        }
    }
}

struct WaveformView: View {
    @State private var phase = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, to: width, by: 5) {
                    let angle = (Double(x) / Double(width) * 2 * .pi) + phase
                    let y = sin(angle * 3) * 10 + sin(angle * 2) * 15 + sin(angle) * 5
                    path.addLine(to: CGPoint(x: x, y: midHeight + CGFloat(y)))
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
        .onReceive(timer) { _ in
            phase += 0.1
        }
    }
}

class EmotionViewModel: ObservableObject {
    @Published var analysisMode: AnalysisMode = .voice
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var detectedEmotion = ""
    @Published var confidenceScore: Double = 0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            // 语音识别权限检查
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            // 麦克风权限检查
        }
    }
    
    func startRecording(completion: @escaping (String, Double) -> Void) {
        isRecording = true
        transcribedText = ""
        detectedEmotion = ""
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else { return }
            
            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    
                    // 每5秒进行一次情绪分析
                    if result.isFinal || error != nil {
                        self.analyzeEmotion(self.transcribedText, completion: completion)
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
        } catch {
            print("语音识别启动失败: \(error)")
            isRecording = false
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        
        // 分析停止录音时的完整文本
        if !transcribedText.isEmpty {
            analyzeEmotion(transcribedText) { emotion, confidence in
                self.detectedEmotion = emotion
                self.confidenceScore = confidence
            }
        }
    }
    
    func analyzeText(_ text: String, completion: @escaping (String, Double) -> Void) {
        if text.isEmpty {
            return
        }
        
        // 分析文本情绪
        analyzeEmotion(text) { emotion, confidence in
            self.detectedEmotion = emotion
            self.confidenceScore = confidence
            completion(emotion, confidence)
        }
    }
    
    private func analyzeEmotion(_ text: String, completion: @escaping (String, Double) -> Void) {
        // 初始化情绪和置信度
        var emotion = "中性"
        var confidenceScore = 0.0
        
        // 检查文本是否为空
        guard !text.isEmpty else {
            DispatchQueue.main.async {
                completion(emotion, confidenceScore)
            }
            return
        }
        
        // 调用情绪分析管理器
        EmotionAnalysisManager.shared.analyzeEmotion(from: text) { result, confidence in
            DispatchQueue.main.async {
                completion(result, confidence)
            }
        }
    }
} 