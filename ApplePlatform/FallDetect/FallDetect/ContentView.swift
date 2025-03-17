//
//  ContentView.swift
//  FallDetect
//
//  Created by BaronXuan on 3/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RecordItem]  // 使用RecordItem替代Item
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        DeviceAdaptiveView {
            // 紧凑视图（iPhone）
            TabView {
                FallDetectionView()
                    .tabItem {
                        Label("摔倒检测", systemImage: "camera.fill")
                    }
                
                EmotionDetectionView()
                    .tabItem {
                        Label("情绪分析", systemImage: "heart.text.square.fill")
                    }
                
                HistoryView(items: items, deleteItems: deleteItems, addItem: addItem)
                    .tabItem {
                        Label("历史记录", systemImage: "clock.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gearshape.fill")
                    }
            }
            .accentColor(.blue)
        } regularContent: {
            // 宽视图（iPad/Vision Pro）
            NavigationSplitView {
                List {
                    NavigationLink {
                        FallDetectionView()
                    } label: {
                        Label("摔倒检测", systemImage: "camera.fill")
                    }
                    
                    NavigationLink {
                        EmotionDetectionView()
                    } label: {
                        Label("情绪分析", systemImage: "heart.text.square.fill")
                    }
                    
                    NavigationLink {
                        HistoryView(items: items, deleteItems: deleteItems, addItem: addItem)
                    } label: {
                        Label("历史记录", systemImage: "clock.fill")
                    }
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("设置", systemImage: "gearshape.fill")
                    }
                }
                .navigationTitle("功能菜单")
            } detail: {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "figure.fall.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("摔倒检测与情绪分析")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("请从侧边栏选择功能")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 5)
                    )
                    .padding()
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = RecordItem(timestamp: Date())  // 使用RecordItem替代Item
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

// 设备适配视图容器
struct DeviceAdaptiveView<CompactContent: View, RegularContent: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var compactContent: () -> CompactContent
    var regularContent: () -> RegularContent
    
    init(@ViewBuilder compactContent: @escaping () -> CompactContent,
         @ViewBuilder regularContent: @escaping () -> RegularContent) {
        self.compactContent = compactContent
        self.regularContent = regularContent
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            compactContent()
        } else {
            regularContent()
        }
    }
}

// 平台检测
extension View {
    func onVisionOS<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(visionOS)
        return content()
        #else
        return self
        #endif
    }
    
    func oniOS<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        return content()
        #else
        return self
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RecordItem.self, inMemory: true)  // 使用RecordItem替代Item
}
