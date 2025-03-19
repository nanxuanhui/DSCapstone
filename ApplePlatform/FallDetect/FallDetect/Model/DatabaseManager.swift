//
//  DatabaseManager.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import Foundation
import SwiftData
import SwiftUI

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private init() {}
    
    // 保存摔倒检测记录
    func saveFallDetectionRecord(
        in modelContext: ModelContext,
        imageData: Data? = nil,
        confidenceScore: Double? = nil,
        details: String? = "检测到摔倒事件",
        helpRequested: Bool = false,
        severity: String? = nil,
        actionTaken: String? = nil
    ) {
        let fallItem = RecordItem(
            timestamp: Date(),
            type: "fall",
            details: details,
            imageData: imageData,
            confidenceScore: confidenceScore,
            fallSeverity: severity,
            actionTaken: actionTaken,
            helpRequested: helpRequested
        )
        
        modelContext.insert(fallItem)
        
        do {
            try modelContext.save()
            print("摔倒检测记录保存成功")
        } catch {
            print("保存摔倒检测记录失败: \(error)")
        }
    }
    
    // 根据类型获取所有记录
    func fetchRecords(type: String?, in modelContext: ModelContext) -> [RecordItem] {
        let descriptor = FetchDescriptor<RecordItem>(
            predicate: type != nil ? #Predicate<RecordItem> { $0.type == type! } : nil,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            return items
        } catch {
            print("获取记录失败: \(error)")
            return []
        }
    }
    
    // 删除记录
    func deleteRecord(_ item: RecordItem, in modelContext: ModelContext) {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            print("记录删除成功")
        } catch {
            print("删除记录失败: \(error)")
        }
    }
    
    // 删除所有记录
    func deleteAllRecords(type: String? = nil, in modelContext: ModelContext) {
        let records = fetchRecords(type: type, in: modelContext)
        for record in records {
            modelContext.delete(record)
        }
        
        do {
            try modelContext.save()
            print("所有记录删除成功")
        } catch {
            print("删除所有记录失败: \(error)")
        }
    }
    
    // 获取统计数据
    func getStatistics(in modelContext: ModelContext) -> (totalFall: Int, lastWeekFall: Int) {
        let allRecords = fetchRecords(type: nil, in: modelContext)
        
        let fallRecords = allRecords.filter { $0.type == "fall" }
        
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        
        let lastWeekFall = fallRecords.filter { $0.timestamp >= oneWeekAgo }.count
        
        return (fallRecords.count, lastWeekFall)
    }
} 