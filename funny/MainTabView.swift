//
//  MainTabView.swift
//  funny
//
//  Created by Cascade on 2025/5/19.
//

import SwiftUI
import CoreHaptics

struct MainTabView: View {
    // 当前选中的标签页
    @State private var selectedTab: TabItem = .home
    
    // 触觉引擎
    @State private var engine: CHHapticEngine?
    
    // 用于重置卡片堆的触发器
    @State private var resetCardTrigger: Bool = false
    
    // 用于页面切换动画
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 内容区域
            TabContent(selectedTab: selectedTab, resetCardTrigger: $resetCardTrigger)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 自定义底部导航栏
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            prepareHaptics()
        }
    }
    
    // 自定义底部导航栏
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        // 如果点击的是已选中的Card标签页，则触发重置
                        if selectedTab == tab && tab == .card {
                            resetCardTrigger = true
                            playHapticFeedback()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                            playHapticFeedback()
                        }
                    }
                )
                
                if tab != TabItem.allCases.last {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // 准备触觉引擎
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("触觉引擎启动错误: \(error.localizedDescription)")
        }
    }
    
    // 播放触觉反馈
    private func playHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        // 创建触觉事件
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("触觉反馈错误: \(error.localizedDescription)")
        }
    }
}

// 标签页内容视图
struct TabContent: View {
    let selectedTab: TabItem
    @Binding var resetCardTrigger: Bool
    
    var body: some View {
        // 使用ZStack直接显示当前选中的标签页，不使用过渡动画
        ZStack {
            switch selectedTab {
            case .home:
                HomeView()
            case .printer:
                ReceiptPrinterView()
            case .card:
                CardView(resetTrigger: $resetCardTrigger)
            }
        }
    }
}

#Preview {
    MainTabView()
}
