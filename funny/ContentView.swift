//
//  ContentView.swift
//  funny
//
//  Created by 湖泊 on 2025/5/15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // 背景色 - 浅灰色背景增强打印机的立体感
            Color.white
                .ignoresSafeArea()
            
            // 打印机收据视图
            ReceiptPrinterView()
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
