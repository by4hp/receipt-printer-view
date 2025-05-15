//
//  ReceiptPrinterView.swift
//  funny
//
//  Created by Cascade on 2025/5/15.
//

import SwiftUI
import CoreHaptics

struct ReceiptPrinterView: View {
    // 添加状态变量来控制收据的显示状态
    @State private var receiptOffset: CGFloat = -500
    @State private var isBlinking: Bool = false
    @State private var isPrinted: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    // 震动引擎
    @State private var engine: CHHapticEngine?
    
    // 准备震动引擎
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("创建震动引擎失败: \(error.localizedDescription)")
        }
    }
    
    // 简单震动
    func simpleSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // 中等强度震动
    func mediumSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // 复杂震动模式
    func complexSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        // 创建强度和锐度曲线
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let decay = CHHapticEventParameter(parameterID: .decayTime, value: 0.2)
        
        // 创建事件
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness, decay], relativeTime: 0)
        events.append(event)
        
        // 连续震动
        for i in stride(from: 0.1, to: 0.3, by: 0.05) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.8))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.5))
            
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("播放震动失败: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        ZStack {
            // 打印机头部 - 灰色金属质感，有立体阴影，始终固定在顶部
            VStack {
                Spacer().frame(height: 30) // 增加到顶部的距离
                PrinterHead(isBlinking: isBlinking)
                    .onTapGesture(count: 1, perform: {
                        // 如果已经打印出来，再次点击则收回
                        if isPrinted {
                            // 收缩动画
                            simpleSuccess() // 简单震动反馈
                            
                            // 开始闪烁状态灯
                            withAnimation(.easeInOut(duration: 0.3).repeatForever()) {
                                isBlinking = true
                            }
                            
                            // 快速收回收据
                            withAnimation(.easeIn(duration: 1.5)) {
                                receiptOffset = -500 // 收回到打印机内
                            }
                            
                            // 打印完成后停止闪烁
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                                withAnimation {
                                    isBlinking = false
                                    isPrinted = false
                                }
                            }
                        } else {
                            // 点击时开始打印动画
                            receiptOffset = -500 // 先将收据隐藏在打印机内
                            
                            // 开始闪烁状态灯
                            withAnimation(.linear(duration: 0.3).repeatForever()) {
                                isBlinking = true
                            }
                            
                            // 使用线性动画和震动效果
                            
                            // 初始震动
                            simpleSuccess()
                            
                            // 单一连续动画
                            withAnimation(.linear(duration: 5.0)) {
                                receiptOffset = 55 // 直接设置最终位置
                            }
                            
                            // 打印过程中的震动效果
                            // 均匀分布震动效果
                            for i in 1...10 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                                    // 根据进度调整震动强度
                                    if i < 3 {
                                        simpleSuccess() // 开始时轻微震动
                                    } else if i < 8 {
                                        // 中间过程中等强度震动
                                        if i % 2 == 0 { // 间隔使用不同强度
                                            simpleSuccess()
                                        } else {
                                            mediumSuccess()
                                        }
                                    } else {
                                        // 结束时较强震动
                                        mediumSuccess()
                                    }
                                }
                            }
                            
                            // 最后一次震动，打印完成
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                complexSuccess()
                            }
                            
                            // 打印完成后停止闪烁并更新状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                                withAnimation {
                                    isBlinking = false
                                    isPrinted = true // 设置为已打印状态
                                }
                            }
                        }
                    })
                
                Spacer() // 使打印机始终保持在顶部
            }
            .zIndex(1) // 打印机头部在中间层
            
            // 收据纸张 - 放在最上层
            // 创建一个裁剪区域，只显示出纸口下方的部分
            ZStack(alignment: .top) {
                    ReceiptPaper()
                        .frame(width: 300)
                        .offset(y: receiptOffset + dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    isDragging = true
                                    // 直接使用拖动的位移量，不限制范围
                                    dragOffset = gesture.translation.height
                                }
                                .onEnded { gesture in
                                    isDragging = false
                                    
                                    // 如果向下拖动超过一定距离，设置为已打印状态
                                    if !isPrinted && gesture.translation.height > 150 {
                                        withAnimation(.spring()) {
                                            isPrinted = true
                                            isBlinking = true
                                            dragOffset = 0
                                            receiptOffset = 55 // 直接设置为展开状态
                                        }
                                        
                                        // 模拟打印完成后的震动和闪烁停止
                                        mediumSuccess()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation {
                                                isBlinking = false
                                            }
                                        }
                                    } 
                                    // 如果向上拖动超过一定距离，收回收据
                                    else if isPrinted && gesture.translation.height < -150 {
                                        withAnimation(.spring()) {
                                            isPrinted = false
                                            dragOffset = 0
                                            receiptOffset = -500 // 收回到打印机内
                                        }
                                        simpleSuccess()
                                    }
                                    // 其他情况下回弹到当前状态
                                    else {
                                        withAnimation(.spring()) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
            }
            .frame(width: 350, height: 800)
            .mask(
                Rectangle()
                    .frame(width: 350, height: 700)
                    .offset(y: 80) // 相对于出纸口位置下移20点
            )
            .zIndex(3)
            .allowsHitTesting(true) // 允许所有状态下都可以交互
        }
        .frame(maxWidth: 350)
        .onAppear {
            prepareHaptics()
        }
    }
}

// 打印机头部组件
struct PrinterHead: View {
    var isBlinking: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            // 出纸口 - 置于底部（放在前面使其显示在下层）
            ZStack {
                // 外部灰色框架
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex: "EEEEEE"), location: 0.0),
                                .init(color: Color(hex: "DDDADA"), location: 0.5),
                                .init(color: Color(hex: "C5C5C5"), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 340, height: 40)
                    .cornerRadius(5)
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 338, height: 38)
                            .cornerRadius(5)
                    )
                
                // 内部黑色梯形出纸口 - 可点击区域
                Trapezoid()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 350, height: 10)
                    .offset(y: 6) // 将梯形下移
            }
            .offset(y: 25) // 向下偏移，使其突出打印机头部
            
            // 打印机头部主体
            ZStack(alignment: .leading) {
                // 打印机头部背景 - 灰色金属质感
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(hex: "BABABA"), location: 0.0),
                                    .init(color: Color(hex: "C5C5C5"), location: 0.59),
                                    .init(color: Color(hex: "FFFFFF"), location: 0.77),
                                    .init(color: Color(hex: "C5C5C5"), location: 0.87),
                                    .init(color: Color(hex: "A1A1A1"), location: 1.0)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 90)
                        .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                
                HStack {
                    // 品牌标识
                    Text("e-print")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    // 状态灯
                    HStack(spacing: 5) {
                        // 第一个状态灯，始终保持亮起
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(0.8), radius: 3, x: 0, y: 0)
                        
                        // 第二个状态灯，闪烁时几乎全暗，不闪烁时亮度中等
                        Circle()
                            .fill(Color.green.opacity(isBlinking ? 0.1 : 0.8))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(isBlinking ? 0 : 0.6), radius: 3, x: 0, y: 0)
                        
                        // 第三个状态灯，闪烁时非常亮，不闪烁时几乎全暗
                        Circle()
                            .fill(Color.green.opacity(isBlinking ? 1.0 : 0.2))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(isBlinking ? 0.8 : 0), radius: 3, x: 0, y: 0)
                    }
                    .padding(.trailing, 20) // 添加右侧填充，使状态灯保持一定的距离
                }
                .offset(y:20)
            }
        }
        .padding(.bottom, 20) // 添加底部填充，为出纸口留出空间
    }
}

// 收据纸张组件
struct ReceiptPaper: View {
    // 格式化当前日期
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    var body: some View {
        VStack(spacing: 0) {
            // 收据内容
            VStack(spacing: 15) {
                // 成功图标
                VStack(spacing: 5) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                .padding(.top, 20)
                
                // 标题和时间
                VStack(spacing: 5) {
                    Text(" Daily to Do List")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(formattedDate())
                        
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.bottom, 10)
                
                // 早晨
                Text("早晨")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                
                VStack(spacing: 8) {
                    ReceiptItem(name: "5:00", price: "喝一杯黑咖啡")
                    ReceiptItem(name: "6:30", price: "空腹散步思考")
                    ReceiptItem(name: "7:30", price: "挑一件黑领毛衣出门")
                }
                .padding(.bottom, 10)
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // 下午
                Text("下午")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                
                VStack(spacing: 8) {
                    ReceiptItem(name: "12:00", price: "与团队共进简单午餐")
                    ReceiptItem(name: "14:00", price: "设计评审会议")
                    ReceiptItem(name: "16:00", price: "与工程师一对一讨论")
                }
                .padding(.bottom, 10)
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // 晚上
                Text("晚上")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                
                VStack(spacing: 8) {
                    ReceiptItem(name: "18:00", price: "去塞纳河边散步")
                    ReceiptItem(name: "19:30", price: "与家人共进素食晒餐")
                    ReceiptItem(name: "21:00", price: "冷静思考产品未来")
                }
                .padding(.bottom, 15)
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // 名言
                HStack {
                    Spacer()
                    Text("“保持简约，专注本质”")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                }
                .padding(.vertical, 10)
                
                // 签名
                HStack {
                    Spacer()
                    Text("— Steve Jobs")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: 270) // 限制内容的最大宽度
            .background(Color(hex: "F1EFEF"))
            
            // // 锯齿边缘
            // ZigzagEdge()
            //     .fill(Color.white)
            //     .frame(height: 20)
            //     .offset(y: )
        }
        .frame(width: 300) // 设置收据纸张的宽度
        .background(Color(hex: "F1EFEF"))
        .cornerRadius(2)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

// 收据项目组件
struct ReceiptItem: View {
    let name: String
    let price: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
            
            Text(price)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}

// 锯齿边缘形状
struct ZigzagEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let zigzagWidth: CGFloat = 10
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 创建锯齿形状
        var x: CGFloat = 0
        while x < width {
            path.addLine(to: CGPoint(x: x + zigzagWidth / 2, y: height))
            path.addLine(to: CGPoint(x: x + zigzagWidth, y: 0))
            x += zigzagWidth
        }
        
        path.addLine(to: CGPoint(x: width, y: 0))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ReceiptPrinterView()
}

// 扩展Color以支持十六进制颜色代码
// 梯形形状定义
struct Trapezoid: Shape {
    var cornerRadius: CGFloat = 1.5
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 定义梯形的四个点
        let topLeftPoint = CGPoint(x: rect.width * 0.05, y: 0)
        let topRightPoint = CGPoint(x: rect.width * 0.95, y: 0)
        let bottomRightPoint = CGPoint(x: rect.width * 0.94, y: rect.height)
        let bottomLeftPoint = CGPoint(x: rect.width * 0.06, y: rect.height)
        
        // 计算圆角半径，对于底部使用更小的半径
        let maxRadius = min(rect.width, rect.height) * 0.15
        let radius = min(cornerRadius, maxRadius)
        
        // 上部圆角的半径
        let topRadius = radius
        // 底部圆角的半径（更小）
        let bottomRadius = radius * 0.5
        
        // 使用贝塞尔曲线创建圆角梯形
        // 左上角
        path.move(to: CGPoint(x: topLeftPoint.x + topRadius, y: topLeftPoint.y))
        
        // 上边
        path.addLine(to: CGPoint(x: topRightPoint.x - topRadius, y: topRightPoint.y))
        
        // 右上角
        path.addQuadCurve(to: CGPoint(x: topRightPoint.x, y: topRightPoint.y + topRadius), 
                         control: topRightPoint)
        
        // 右边
        path.addLine(to: CGPoint(x: bottomRightPoint.x, y: bottomRightPoint.y - bottomRadius))
        
        // 右下角 - 使用更小的半径
        path.addQuadCurve(to: CGPoint(x: bottomRightPoint.x - bottomRadius, y: bottomRightPoint.y),
                         control: bottomRightPoint)
        
        // 下边
        path.addLine(to: CGPoint(x: bottomLeftPoint.x + bottomRadius, y: bottomLeftPoint.y))
        
        // 左下角 - 使用更小的半径
        path.addQuadCurve(to: CGPoint(x: bottomLeftPoint.x, y: bottomLeftPoint.y - bottomRadius),
                         control: bottomLeftPoint)
        
        // 左边
        path.addLine(to: CGPoint(x: topLeftPoint.x, y: topLeftPoint.y + topRadius))
        
        // 左上角
        path.addQuadCurve(to: CGPoint(x: topLeftPoint.x + topRadius, y: topLeftPoint.y),
                         control: topLeftPoint)
        
        path.closeSubpath()
        
        return path
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
