//
//  HistoryView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    var items: [RecordItem]
    var deleteItems: (IndexSet) -> Void
    var addItem: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone上使用原有的列表布局
                navigationBasedLayout
            } else {
                // iPad/Vision Pro上使用并排布局
                directLayout
            }
        }
    }
    
    // 原有的导航式布局(iPhone用)
    var navigationBasedLayout: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计摘要
                StatsSummaryView(modelContext: modelContext)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                
                // 分类过滤器
                Picker("筛选", selection: $selectedFilter) {
                    Text("全部").tag(HistoryFilter.all)
                    Text("摔倒事件").tag(HistoryFilter.fallOnly)
                    Text("情绪分析").tag(HistoryFilter.emotionOnly)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 历史记录列表
                if filteredItems.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        Text("没有找到记录")
                            .font(.headline)
                        Text("选择不同的过滤器或添加新的记录")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                HistoryDetailView(item: item)
                            } label: {
                                HistoryItemRow(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingStatsView = true
                        }) {
                            Label("查看数据统计", systemImage: "chart.bar")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("清除所有记录", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    DatabaseManager.shared.deleteAllRecords(
                        type: selectedFilter == .all ? nil : (selectedFilter == .fallOnly ? "fall" : "emotion"),
                        in: modelContext
                    )
                }
            } message: {
                Text("确定要删除所有\(selectedFilter == .all ? "" : (selectedFilter == .fallOnly ? "摔倒检测" : "情绪分析"))记录吗？此操作无法撤销。")
            }
            .sheet(isPresented: $showingStatsView) {
                StatsView(modelContext: modelContext)
            }
        }
    }
    
    // 新的直接布局(iPad/Vision Pro用)
    var directLayout: some View {
        HStack(spacing: 0) {
            // 左侧类别选择区
            VStack {
                Text("记录类型")
                    .font(.title2)
                    .padding(.top)
                
                Button(action: {
                    // 显示所有记录
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("所有记录")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // 显示摔倒记录
                }) {
                    HStack {
                        Image(systemName: "figure.fall")
                        Text("摔倒记录")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // 显示情绪记录
                }) {
                    HStack {
                        Image(systemName: "heart.text.square")
                        Text("情绪记录")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    // 统计数据
                }) {
                    HStack {
                        Image(systemName: "chart.pie")
                        Text("统计分析")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .frame(width: 250)
            .padding()
            .background(Color(.secondarySystemBackground))
            
            // 右侧内容区
            VStack {
                // 顶部标题和筛选
                HStack {
                    Text("历史记录")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                    
                    Button(action: addItem) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
                .padding()
                
                // 记录内容直接显示为网格
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                        ForEach(items) { item in
                            RecordCard(item: item)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedFilter: HistoryFilter = .all
    @State private var showingDeleteAlert = false
    @State private var showingStatsView = false
    
    private var filteredItems: [RecordItem] {
        switch selectedFilter {
        case .all:
            return items
        case .fallOnly:
            return items.filter { $0.type == "fall" }
        case .emotionOnly:
            return items.filter { $0.type == "emotion" }
        }
    }
}

enum HistoryFilter {
    case all, fallOnly, emotionOnly
}

struct HistoryItemRow: View {
    let item: RecordItem
    
    var body: some View {
        HStack(spacing: 15) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(item.type == "fall" ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: item.type == "fall" ? "figure.fall" : "heart.text.square")
                    .font(.system(size: 20))
                    .foregroundColor(item.type == "fall" ? .red : .blue)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type == "fall" ? "摔倒事件" : "情绪分析")
                    .font(.headline)
                
                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let details = item.details {
                    Text(details)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 严重程度指示器（仅用于摔倒事件）
            if item.type == "fall", let confidenceScore = item.confidenceScore {
                SeverityIndicator(score: confidenceScore)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SeverityIndicator: View {
    let score: Double
    
    var body: some View {
        VStack {
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)
            
            Text(severityText)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var severityColor: Color {
        if score > 0.8 {
            return .red
        } else if score > 0.5 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    private var severityText: String {
        if score > 0.8 {
            return "严重"
        } else if score > 0.5 {
            return "中度"
        } else {
            return "轻微"
        }
    }
}

struct HistoryDetailView: View {
    let item: RecordItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 头部
                HStack {
                    Text(item.type == "fall" ? "摔倒事件详情" : "情绪分析详情")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .complete))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // 分割线
                Divider()
                    .padding(.horizontal)
                
                // 详情内容
                Group {
                    if item.type == "fall" {
                        FallDetailContent(item: item)
                    } else {
                        EmotionDetailContent(item: item)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

struct FallDetailContent: View {
    let item: RecordItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 事件图像
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(12)
                    
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
            
            // 事件信息
            GroupBox(label: Text("事件信息").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(title: "发生时间", value: item.timestamp.formatted(date: .numeric, time: .standard))
                    
                    if let details = item.details {
                        InfoRow(title: "详细描述", value: details)
                    }
                    
                    if let confidenceScore = item.confidenceScore {
                        InfoRow(title: "置信度", value: "\(Int(confidenceScore * 100))%")
                    }
                }
                .padding(.vertical)
            }
            
            // 位置信息
            GroupBox(label: Text("位置信息").font(.headline)) {
                Text("暂无位置信息")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}

struct EmotionDetailContent: View {
    let item: RecordItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 情绪结果
            if let emotionType = item.emotionType {
                GroupBox {
                    HStack(spacing: 20) {
                        EmotionIcon(emotion: emotionType)
                        
                        VStack(alignment: .leading) {
                            Text("检测到的情绪")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(emotionType)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(emotionColor(emotionType))
                        }
                        
                        Spacer()
                        
                        if let confidenceScore = item.confidenceScore {
                            Text("\(Int(confidenceScore * 100))%")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            
            // 分析内容
            GroupBox(label: Text("分析内容").font(.headline)) {
                if let fullText = item.fullText {
                    Text(fullText)
                        .padding()
                } else if let details = item.details {
                    Text(details)
                        .padding()
                } else {
                    Text("暂无分析内容")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            
            // 其他信息
            GroupBox(label: Text("分析信息").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(title: "分析时间", value: item.timestamp.formatted(date: .numeric, time: .standard))
                    InfoRow(title: "分析类型", value: "文本分析")
                }
                .padding(.vertical)
            }
        }
    }
    
    func emotionColor(_ emotion: String) -> Color {
        switch emotion {
        case "开心": return .green
        case "悲伤": return .blue
        case "愤怒": return .red
        case "焦虑": return .orange
        case "恐惧": return .purple
        case "惊讶": return .yellow
        case "中性": return .gray
        default: return .gray
        }
    }
}

struct StatsSummaryView: View {
    var modelContext: ModelContext
    @State private var stats = (totalFall: 0, totalEmotion: 0, lastWeekFall: 0, lastWeekEmotion: 0)
    
    var body: some View {
        HStack {
            StatBox(title: "摔倒事件", count: stats.totalFall, recent: stats.lastWeekFall, iconName: "figure.fall", color: .red)
            StatBox(title: "情绪分析", count: stats.totalEmotion, recent: stats.lastWeekEmotion, iconName: "heart.text.square", color: .blue)
        }
        .onAppear {
            stats = DatabaseManager.shared.getStatistics(in: modelContext)
        }
    }
}

struct StatBox: View {
    let title: String
    let count: Int
    let recent: Int
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("过去7天: \(recent)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatsView: View {
    var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var items: [RecordItem] = []
    @State private var timeRange: TimeRange = .week
    
    enum TimeRange {
        case week, month, year, all
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 时间范围选择器
                    Picker("时间范围", selection: $timeRange) {
                        Text("周").tag(TimeRange.week)
                        Text("月").tag(TimeRange.month)
                        Text("年").tag(TimeRange.year)
                        Text("全部").tag(TimeRange.all)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 记录数量图表
                    GroupBox("记录数量") {
                        if chartData.isEmpty {
                            Text("没有数据")
                                .foregroundColor(.gray)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        } else {
                            Chart(chartData, id: \.date) { item in
                                BarMark(
                                    x: .value("日期", item.date),
                                    y: .value("数量", item.fall)
                                )
                                .foregroundStyle(Color.red)
                                .annotation(position: .top) {
                                    if item.fall > 0 {
                                        Text("\(item.fall)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                BarMark(
                                    x: .value("日期", item.date),
                                    y: .value("数量", item.emotion)
                                )
                                .foregroundStyle(Color.blue)
                                .annotation(position: .top) {
                                    if item.emotion > 0 {
                                        Text("\(item.emotion)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .chartForegroundStyleScale([
                                "摔倒": .red,
                                "情绪": .blue
                            ])
                            .chartLegend(position: .bottom)
                            .frame(height: 200)
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    // 情绪分布图表
                    if hasEmotionRecords {
                        GroupBox("情绪分布") {
                            if emotionDistribution.isEmpty {
                                Text("没有情绪数据")
                                    .foregroundColor(.gray)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(emotionDistribution, id: \.emotion) { item in
                                    SectorMark(
                                        angle: .value("数量", item.count),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .foregroundStyle(by: .value("情绪", item.emotion))
                                    .annotation(position: .overlay) {
                                        Text("\(item.count)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .chartLegend(position: .bottom)
                                .frame(height: 200)
                                .padding()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 摔倒严重程度分布
                    if hasFallRecords {
                        GroupBox("摔倒严重程度") {
                            if fallSeverityDistribution.isEmpty {
                                Text("没有摔倒数据")
                                    .foregroundColor(.gray)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(fallSeverityDistribution, id: \.severity) { item in
                                    SectorMark(
                                        angle: .value("数量", item.count),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .foregroundStyle(by: .value("严重程度", item.severity))
                                    .annotation(position: .overlay) {
                                        Text("\(item.count)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .chartLegend(position: .bottom)
                                .frame(height: 200)
                                .padding()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("数据统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadData()
            }
            .onChange(of: timeRange) { _, _ in
                loadData()
            }
        }
    }
    
    // 添加缺失的计算属性和方法
    private var hasFallRecords: Bool {
        return items.contains { $0.type == "fall" }
    }
    
    private var hasEmotionRecords: Bool {
        return items.contains { $0.type == "emotion" }
    }
    
    private func loadData() {
        let allItems = DatabaseManager.shared.fetchRecords(type: nil, in: modelContext)
        
        let calendar = Calendar.current
        let now = Date()
        
        let filteredItems: [RecordItem]
        
        switch timeRange {
        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now)!
            filteredItems = allItems.filter { $0.timestamp >= startOfWeek }
        case .month:
            let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            filteredItems = allItems.filter { $0.timestamp >= startOfMonth }
        case .year:
            let startOfYear = calendar.date(byAdding: .year, value: -1, to: now)!
            filteredItems = allItems.filter { $0.timestamp >= startOfYear }
        case .all:
            filteredItems = allItems
        }
        
        items = filteredItems
    }
    
    private var chartData: [(date: Date, fall: Int, emotion: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        var data: [(date: Date, fall: Int, emotion: Int)] = []
        
        let numberOfDays: Int
        
        switch timeRange {
        case .week:
            numberOfDays = 7
        case .month:
            numberOfDays = 30
        case .year:
            numberOfDays = 12 // 按月聚合
        case .all:
            if items.isEmpty {
                numberOfDays = 0
            } else {
                let oldestDate = items.map { $0.timestamp }.min()!
                numberOfDays = calendar.dateComponents([.day], from: oldestDate, to: now).day! + 1
            }
        }
        
        if timeRange == .year {
            // 按月聚合
            for i in 0..<numberOfDays {
                let date = calendar.date(byAdding: .month, value: -i, to: now)!
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                
                let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                
                let fallCount = items.filter { $0.type == "fall" && $0.timestamp >= startOfMonth && $0.timestamp < nextMonth }.count
                let emotionCount = items.filter { $0.type == "emotion" && $0.timestamp >= startOfMonth && $0.timestamp < nextMonth }.count
                
                data.append((date: startOfMonth, fall: fallCount, emotion: emotionCount))
            }
        } else {
            // 按天聚合
            for i in 0..<numberOfDays {
                let date = calendar.date(byAdding: .day, value: -i, to: now)!
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let fallCount = items.filter { $0.type == "fall" && $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.count
                let emotionCount = items.filter { $0.type == "emotion" && $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.count
                
                data.append((date: startOfDay, fall: fallCount, emotion: emotionCount))
            }
        }
        
        return data.reversed()
    }
    
    private var emotionDistribution: [(emotion: String, count: Int)] {
        let emotionItems = items.filter { $0.type == "emotion" && $0.emotionType != nil }
        var emotionCounts: [String: Int] = [:]
        
        for item in emotionItems {
            if let emotion = item.emotionType {
                emotionCounts[emotion, default: 0] += 1
            }
        }
        
        return emotionCounts.map { (emotion: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var fallSeverityDistribution: [(severity: String, count: Int)] {
        let fallItems = items.filter { $0.type == "fall" }
        var severityCounts: [String: Int] = [:]
        
        for item in fallItems {
            if let severity = item.fallSeverity {
                severityCounts[severity, default: 0] += 1
            } else if let confidence = item.confidenceScore {
                let severity = confidence > 0.8 ? "严重" : (confidence > 0.5 ? "中度" : "轻微")
                severityCounts[severity, default: 0] += 1
            }
        }
        
        return severityCounts.map { (severity: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.gray)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// 记录卡片视图
struct RecordCard: View {
    let item: RecordItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(item.type == "fall" ? Color.red : Color.blue)
                    .frame(width: 12, height: 12)
                
                Text(item.type == "fall" ? "摔倒记录" : "情绪记录")
                    .font(.headline)
                
                Spacer()
                
                Text(item.timestamp.formatted(date: .numeric, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 显示详细内容
            if item.type == "fall" {
                fallRecordDetails
            } else {
                emotionRecordDetails
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    var fallRecordDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(8)
            }
            
            HStack {
                Text("严重程度:")
                    .foregroundColor(.secondary)
                Text(getFallSeverity())
                    .foregroundColor(getFallSeverity() == "严重" ? .red : .orange)
            }
            
            Text("细节: \(item.details)")
                .lineLimit(2)
        }
    }
    
    var emotionRecordDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("情绪类型:")
                    .foregroundColor(.secondary)
                Text(item.emotionType ?? "未知")
                    .bold()
            }
            
            HStack {
                Text("置信度:")
                    .foregroundColor(.secondary)
                Text("\(Int((item.confidenceScore ?? 0.0) * 100))%")
            }
            
            if let fullText = item.fullText {
                Text("内容: \(fullText)")
                    .lineLimit(2)
            }
        }
    }
    
    private func getFallSeverity() -> String {
        if let severity = item.fallSeverity {
            return severity
        } else if let score = item.confidenceScore {
            if score > 0.8 {
                return "严重"
            } else if score > 0.5 {
                return "中度"
            } else {
                return "轻微"
            }
        }
        return "未知"
    }
}

// 情绪图标组件
struct EmotionIcon: View {
    let emotion: String
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 22))
            .foregroundColor(iconColor)
    }
    
    // 根据情绪类型返回图标名称
    var iconName: String {
        switch emotion.lowercased() {
        case "高兴":
            return "face.smiling"
        case "悲伤":
            return "cloud.rain"
        case "愤怒":
            return "flame"
        case "焦虑":
            return "waveform.path.ecg"
        case "平静":
            return "leaf"
        case "惊讶":
            return "exclamationmark.circle"
        default:
            return "questionmark.circle"
        }
    }
    
    // 根据情绪类型返回颜色
    var iconColor: Color {
        switch emotion.lowercased() {
        case "高兴":
            return .green
        case "悲伤":
            return .blue
        case "愤怒":
            return .red
        case "焦虑":
            return .orange
        case "平静":
            return .cyan
        case "惊讶":
            return .purple
        default:
            return .gray
        }
    }
} 