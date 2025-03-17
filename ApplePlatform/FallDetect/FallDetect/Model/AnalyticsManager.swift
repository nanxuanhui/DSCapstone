//
//  AnalyticsManager.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import Foundation
import SwiftData

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // 分析摔倒频率
    func analyzeFallFrequency(items: [RecordItem], timeframe: TimeFrameOption) -> [DateFrequency] {
        let fallItems = items.filter { $0.type == "fall" }
        return calculateFrequency(for: fallItems, timeframe: timeframe)
    }
    
    // 分析情绪变化
    func analyzeEmotionChanges(items: [RecordItem], timeframe: TimeFrameOption) -> [EmotionChange] {
        let emotionItems = items.filter { $0.type == "emotion" && $0.emotionType != nil }
            .sorted { $0.timestamp < $1.timestamp }
        
        var changes: [EmotionChange] = []
        
        for i in 0..<emotionItems.count {
            if i > 0 {
                if let currentEmotion = emotionItems[i].emotionType,
                   let previousEmotion = emotionItems[i-1].emotionType,
                   currentEmotion != previousEmotion {
                    
                    changes.append(EmotionChange(
                        date: emotionItems[i].timestamp,
                        fromEmotion: previousEmotion,
                        toEmotion: currentEmotion,
                        timeGap: emotionItems[i].timestamp.timeIntervalSince(emotionItems[i-1].timestamp)
                    ))
                }
            }
        }
        
        return changes
    }
    
    // 找出情绪模式
    func findEmotionPatterns(items: [RecordItem]) -> [EmotionPattern] {
        let emotionItems = items.filter { $0.type == "emotion" && $0.emotionType != nil }
        var patterns: [String: Int] = [:]
        
        // 简单模式：统计每种情绪的频率
        for item in emotionItems {
            if let emotion = item.emotionType {
                patterns[emotion, default: 0] += 1
            }
        }
        
        return patterns.map { EmotionPattern(emotion: $0.key, frequency: $0.value) }
            .sorted { $0.frequency > $1.frequency }
    }
    
    // 计算时间频率
    private func calculateFrequency(for items: [RecordItem], timeframe: TimeFrameOption) -> [DateFrequency] {
        let calendar = Calendar.current
        var frequencies: [Date: Int] = [:]
        
        for item in items {
            let dateComponent: Date
            
            switch timeframe {
            case .daily:
                // 按天分组
                dateComponent = calendar.startOfDay(for: item.timestamp)
            case .weekly:
                // 按周分组
                let weekdayComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: item.timestamp)
                dateComponent = calendar.date(from: weekdayComponents)!
            case .monthly:
                // 按月分组
                let monthComponents = calendar.dateComponents([.year, .month], from: item.timestamp)
                dateComponent = calendar.date(from: monthComponents)!
            }
            
            frequencies[dateComponent, default: 0] += 1
        }
        
        return frequencies.map { DateFrequency(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

// 分析相关的数据结构
enum TimeFrameOption {
    case daily, weekly, monthly
}

struct DateFrequency: Identifiable {
    var id = UUID()
    var date: Date
    var count: Int
}

struct EmotionChange: Identifiable {
    var id = UUID()
    var date: Date
    var fromEmotion: String
    var toEmotion: String
    var timeGap: TimeInterval // 情绪变化之间的间隔（秒）
}

struct EmotionPattern: Identifiable {
    var id = UUID()
    var emotion: String
    var frequency: Int
} 