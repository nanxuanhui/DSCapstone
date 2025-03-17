//
//  EmotionDetectionManager.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import CoreML
import NaturalLanguage
import Speech
import Foundation
import AVFoundation

class EmotionDetectionManager {
    static let shared = EmotionDetectionManager()
    
    private var emotionModel: MLModel?
    private var isModelLoaded = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private init() {
        loadModel()
    }
    
    func loadModel() {
        // 加载情绪检测模型
        guard let modelURL = Bundle.main.url(forResource: "EmotionAnalysis", withExtension: "mlmodelc") else {
            print("找不到情绪检测模型")
            return
        }
        
        do {
            emotionModel = try MLModel(contentsOf: modelURL)
            isModelLoaded = true
            print("情绪检测模型加载成功")
        } catch {
            print("加载情绪检测模型失败: \(error)")
        }
    }
    
    func reloadModel() {
        isModelLoaded = false
        loadModel()
    }
    
    func analyzeEmotion(from text: String, completion: @escaping (String, Double) -> Void) {
        guard isModelLoaded, let model = emotionModel else {
            completion("未知", 0.0)
            return
        }
        
        // 预处理文本
        let processedText = preprocessText(text)
        
        // 创建模型输入
        do {
            // 注意：这里的输入键需要根据您的模型而定
            let input = try MLDictionaryFeatureProvider(dictionary: ["text": MLFeatureValue(string: processedText)])
            
            // 预测
            if let prediction = try? model.prediction(from: input),
               let emotionOutput = prediction.featureValue(for: "emotion")?.stringValue,
               let confidenceOutput = prediction.featureValue(for: "confidence")?.doubleValue {
                completion(emotionOutput, confidenceOutput)
            } else {
                // 如果模型没有准确的"emotion"和"confidence"输出，使用模拟数据
                simulateEmotionAnalysis(for: text, completion: completion)
            }
        } catch {
            print("情绪分析失败: \(error)")
            simulateEmotionAnalysis(for: text, completion: completion)
        }
    }
    
    private func simulateEmotionAnalysis(for text: String, completion: @escaping (String, Double) -> Void) {
        // 这是模拟情绪分析的函数，仅用于展示目的
        // 在实际应用中应替换为真实模型的输出
        let emotions = ["开心", "悲伤", "愤怒", "焦虑", "恐惧", "惊讶", "中性"]
        let text = text.lowercased()
        
        if text.contains("开心") || text.contains("高兴") || text.contains("快乐") {
            completion("开心", 0.85)
        } else if text.contains("伤心") || text.contains("难过") || text.contains("悲") {
            completion("悲伤", 0.78)
        } else if text.contains("生气") || text.contains("愤怒") || text.contains("气愤") {
            completion("愤怒", 0.82)
        } else if text.contains("担心") || text.contains("焦虑") {
            completion("焦虑", 0.76)
        } else if text.contains("害怕") || text.contains("恐惧") {
            completion("恐惧", 0.79)
        } else if text.contains("惊讶") || text.contains("震惊") {
            completion("惊讶", 0.81)
        } else {
            completion("中性", 0.70)
        }
    }
    
    private func preprocessText(_ text: String) -> String {
        // 文本预处理逻辑
        return text
    }
    
    // MARK: - 语音识别相关方法
    
    func startSpeechRecognition(resultHandler: @escaping (String) -> Void, endHandler: @escaping () -> Void) -> Bool {
        // 检查麦克风权限
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            return false
        }
        
        // 创建语音识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            return false
        }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        // 开始识别
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                resultHandler(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                endHandler()
            }
        }
        
        // 配置音频
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            return true
        } catch {
            print("音频引擎启动失败: \(error)")
            return false
        }
    }
    
    func stopSpeechRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
    }
} 