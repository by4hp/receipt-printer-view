//
//  TabButton.swift
//  funny
//
//  Created by Cascade on 2025/5/19.
//

import SwiftUI

// 自定义标签页按钮组件
struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    // 动画命名空间
    @Namespace private var animation
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 图标
                Image(systemName: tab.iconName)
                    .font(.system(size: isSelected ? 24 : 20))
                    .foregroundColor(isSelected ? tab.color : .gray)
                
                // 标题文本
                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? tab.color : .gray)
                    .opacity(isSelected ? 1 : 0.7)
                    .scaleEffect(isSelected ? 1 : 0.9)
            }
            .frame(minWidth: 70, minHeight: 56)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(tab.color.opacity(0.15))
                        .matchedGeometryEffect(id: "TAB_BACKGROUND", in: animation)
                }
            }
        }
        .buttonStyle(TabButtonStyle())
    }
}

// 自定义按钮样式，添加轻微的按压效果
struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    HStack {
        TabButton(tab: .home, isSelected: true, action: {})
        TabButton(tab: .printer, isSelected: false, action: {})
        TabButton(tab: .card, isSelected: false, action: {})
    }
    .padding()
    .background(.ultraThinMaterial)
    .cornerRadius(25)
    .padding()
}
