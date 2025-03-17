//
//  RecordItem.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import Foundation
import SwiftData

@Model
final class RecordItem {
    // 基本属性
    var id: UUID
    var timestamp: Date
    var type: String // "fall" 或 "emotion"
    
    // 通用属性
    var details: String?
    var imageData: Data?
    var confidenceScore: Double?
    var location: String?
    
    // 情绪检测特有属性
    var emotionType: String?
    var fullText: String?
    var audioData: Data?
    
    // 摔倒检测特有属性
    var fallSeverity: String?
    var actionTaken: String?
    var helpRequested: Bool
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         type: String = "fall",
         details: String? = nil,
         imageData: Data? = nil,
         confidenceScore: Double? = nil,
         location: String? = nil,
         emotionType: String? = nil,
         fullText: String? = nil,
         audioData: Data? = nil,
         fallSeverity: String? = nil,
         actionTaken: String? = nil,
         helpRequested: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.details = details
        self.imageData = imageData
        self.confidenceScore = confidenceScore
        self.location = location
        self.emotionType = emotionType
        self.fullText = fullText
        self.audioData = audioData
        self.fallSeverity = fallSeverity
        self.actionTaken = actionTaken
        self.helpRequested = helpRequested
    }
    
    // 创建摔倒检测记录的便捷方法
    static func createFallRecord(
        timestamp: Date = Date(),
        details: String? = nil,
        imageData: Data? = nil,
        confidenceScore: Double? = nil,
        location: String? = nil,
        fallSeverity: String? = nil,
        actionTaken: String? = nil,
        helpRequested: Bool = false
    ) -> RecordItem {
        return RecordItem(
            timestamp: timestamp,
            type: "fall",
            details: details,
            imageData: imageData,
            confidenceScore: confidenceScore,
            location: location,
            fallSeverity: fallSeverity,
            actionTaken: actionTaken,
            helpRequested: helpRequested
        )
    }
    
    // 创建情绪分析记录的便捷方法
    static func createEmotionRecord(
        timestamp: Date = Date(),
        details: String? = nil,
        confidenceScore: Double? = nil,
        emotionType: String? = nil,
        fullText: String? = nil,
        audioData: Data? = nil
    ) -> RecordItem {
        return RecordItem(
            timestamp: timestamp,
            type: "emotion",
            details: details,
            confidenceScore: confidenceScore,
            emotionType: emotionType,
            fullText: fullText,
            audioData: audioData
        )
    }
} 