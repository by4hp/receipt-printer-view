//
//  TabItem.swift
//  funny
//
//  Created by Cascade on 2025/5/19.
//

import SwiftUI

// 定义应用的主要标签页
enum TabItem: String, CaseIterable {
    case home
    case printer
    case card
    
    // 每个标签页的图标名称（SF Symbols）
    var iconName: String {
        switch self {
        case .home:
            return "house.fill"
        case .printer:
            return "printer.fill"
        case .card:
            return "creditcard.fill"
        }
    }
    
    // 每个标签页的标题
    var title: String {
        switch self {
        case .home:
            return "主页"
        case .printer:
            return "打印机"
        case .card:
            return "卡片"
        }
    }
    
    // 每个标签页的颜色
    var color: Color {
        switch self {
        case .home:
            return .blue
        case .printer:
            return .orange
        case .card:
            return .green
        }
    }
}
