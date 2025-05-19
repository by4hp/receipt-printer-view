//
//  HomeView.swift
//  funny
//
//  Created by Cascade on 2025/5/19.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 内容
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().fill(.white.opacity(0.8)))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text("主页")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("这是应用的主页，可以在这里展示重要信息和功能入口")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    HomeView()
}
