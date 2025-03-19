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