import SwiftUI
import AVFoundation

struct EmotionDetectionView: View {
    @StateObject private var viewModel = EmotionDetectionViewModel()
    @State private var inputText: String = ""
    @State private var showVoiceMode: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题
                Text("情绪分析")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 模式切换
                segmentedControl
                    .padding(.horizontal)
                
                // 内容显示
                if showVoiceMode {
                    voiceModeView
                } else {
                    textModeView
                }
                
                // 结果显示
                resultView
                    .padding()
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .onDisappear {
            if viewModel.isRecording {
                viewModel.stopRecording()
            }
        }
    }
    
    // 分段控制器
    private var segmentedControl: some View {
        Picker("分析模式", selection: $showVoiceMode) {
            Text("语音分析").tag(true)
            Text("文字分析").tag(false)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical, 8)
    }
    
    // 语音模式视图
    private var voiceModeView: some View {
        VStack(spacing: 20) {
            // 状态文本
            Text(viewModel.isRecording ? "正在聆听..." : "点击下方按钮开始录音")
                .font(.headline)
                .foregroundColor(viewModel.isRecording ? .blue : .gray)
                .padding(.vertical, 8)
            
            // 文本显示区域
            ZStack(alignment: .leading) {
                if viewModel.transcribedText.isEmpty {
                    Text("等待您的声音...")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Text(viewModel.transcribedText)
                    .padding()
                    .frame(minHeight: 120)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // 录音按钮
            Button(action: {
                print("麦克风按钮被点击")
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 10)
            .disabled(viewModel.isProcessing)
        }
    }
    
    // 文字模式视图
    private var textModeView: some View {
        VStack(spacing: 20) {
            // 文本输入区域
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("请输入要分析的文字...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $inputText)
                    .padding(3)
                    .frame(minHeight: 120)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // 分析按钮
            Button(action: {
                if !inputText.isEmpty {
                    viewModel.analyzeEmotion(inputText) { emotion, score in
                        viewModel.emotion = emotion
                        viewModel.confidenceScore = score
                    }
                    
                    // 隐藏键盘
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }) {
                Text("分析情绪")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(inputText.isEmpty)
        }
    }
    
    // 结果显示视图
    private var resultView: some View {
        VStack(spacing: 15) {
            Text("分析结果")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 20) {
                resultCard(title: "情绪类型", value: viewModel.emotion)
                resultCard(title: "置信度", value: String(format: "%.0f%%", viewModel.confidenceScore * 100))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    // 结果卡片
    private func resultCard(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
                .padding(.top, 5)
        }
        .frame(minWidth: 120)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// 错误模型
struct EmotionError: Identifiable {
    var id = UUID()
    var message: String
}

struct EmotionDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionDetectionView()
    }
} 