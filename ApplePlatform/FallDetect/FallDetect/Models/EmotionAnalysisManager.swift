//
//  EmotionAnalysisManager.swift
//  FallDetect
//

import Foundation
import NaturalLanguage

class EmotionAnalysisManager {
    static let shared = EmotionAnalysisManager()
    
    private init() {}
    
    func analyzeEmotion(from text: String, completion: @escaping (String, Double) -> Void) {
        // 基本情绪类型
        let emotions = ["高兴", "悲伤", "愤怒", "惊讶", "恐惧", "中性"]
        
        // 情绪关键词映射
        let emotionKeywords: [String: [String]] = [
            "高兴": ["开心", "快乐", "喜悦", "满意", "幸福", "兴奋", "愉快", "欣喜", "好", "棒", "喜欢", "爱", "笑"],
            "悲伤": ["伤心", "难过", "失望", "沮丧", "消沉", "痛苦", "哀伤", "遗憾", "哭", "泪", "苦闷"],
            "愤怒": ["生气", "恼怒", "气愤", "暴躁", "恨", "烦", "怒", "不满", "厌恶"],
            "惊讶": ["惊讶", "震惊", "意外", "吃惊", "不可思议", "惊异", "惊喜"],
            "恐惧": ["害怕", "恐慌", "焦虑", "担心", "紧张", "惊恐", "怕", "惧"],
            "中性": ["普通", "一般", "还行", "可以", "正常", "平静", "平淡"]
        ]
        
        // 使用情感分析模型
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        // 获取整体情感分数
        let (sentimentScore, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let scoreValue = Double(sentimentScore?.rawValue ?? "0") ?? 0
        
        // 统计关键词匹配
        var emotionCounts: [String: Int] = [:]
        for (emotion, keywords) in emotionKeywords {
            let count = keywords.reduce(0) { count, keyword in
                return count + (text.lowercased().contains(keyword.lowercased()) ? 1 : 0)
            }
            emotionCounts[emotion] = count
        }
        
        // 综合情感分数和关键词匹配结果
        var detectedEmotion = "中性"
        var maxCount = 0
        
        for (emotion, count) in emotionCounts {
            if count > maxCount {
                maxCount = count
                detectedEmotion = emotion
            }
        }
        
        // 如果没有明显的情绪关键词，则基于情感分数判断
        if maxCount == 0 {
            if scoreValue > 0.3 {
                detectedEmotion = "高兴"
            } else if scoreValue < -0.3 {
                detectedEmotion = "悲伤"
            } else {
                detectedEmotion = "中性"
            }
        }
        
        // 计算置信度（简化的计算）
        let confidence = min(max(0.5 + Double(maxCount) * 0.1 + abs(scoreValue) * 0.3, 0.5), 0.98)
        
        // 返回结果
        DispatchQueue.main.async {
            completion(detectedEmotion, confidence)
        }
    }
} 