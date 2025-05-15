//
//  ReceiptPrinterView.swift
//  funny
//
//  Created by Cascade on 2025/5/15.
//

import SwiftUI

struct ReceiptPrinterView: View {
    // 添加状态变量来控制收据的显示状态
    @State private var receiptOffset: CGFloat = -510
    
    var body: some View {
        ZStack {
            // 打印机头部 - 灰色金属质感，有立体阴影，始终固定在顶部
            VStack {
                PrinterHead()
                    .contentShape(Rectangle()) // 确保整个区域可点击
                    .onTapGesture {
                        // 点击时开始打印动画
                        receiptOffset = -510 // 先将收据隐藏在打印机内
                        
                        // 使用延迟和多步动画来创建打印效果
                        withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                            receiptOffset = -450 // 开始出来一点
                        }
                        
                        withAnimation(.easeInOut(duration: 1.2).delay(1.0)) {
                            receiptOffset = -400 // 继续出来
                        }
                        
                        withAnimation(.easeInOut(duration: 1.3).delay(1.5)) {
                            receiptOffset = -350 // 继续出来
                        }
                        
                        withAnimation(.easeInOut(duration: 1.4).delay(2.5)) {
                            receiptOffset = -200 // 出来更多
                        }
                        
                        withAnimation(.easeOut(duration: 2).delay(3.5)) {
                            receiptOffset = -20 // 最终位置
                        }
                    }
                
                Spacer() // 使打印机始终保持在顶部
            }
            .zIndex(1) // 打印机头部在中间层
            
            // 收据纸张 - 放在最上层
            // 创建一个裁剪区域，只显示出纸口下方的部分
            ZStack(alignment: .top) {
                    ReceiptPaper()
                        .frame(width: 300)
                        .offset(y: receiptOffset)
            }
            .frame(width: 350, height: 600)
            .mask(
                Rectangle()
                    .frame(width: 350, height: 600)
                    .offset(y: 13) // 整体下移
            )
            .zIndex(3)
        }
        .frame(maxWidth: 350)
    }
}

// 打印机头部组件
struct PrinterHead: View {
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
                    .frame(width: 335, height: 8)
                    .offset(y: 8) // 将梯形下移
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
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                    .padding(.trailing, 20)
                }
            }
        }
        .padding(.bottom, 30) // 添加底部填充，为出纸口留出空间
    }
}

// 收据纸张组件
struct ReceiptPaper: View {
    var body: some View {
        VStack(spacing: 0) {
            // 收据内容
            VStack(spacing: 15) {
                // 成功图标
                Circle()
                    .fill(Color.green)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .padding(.top, 20)
                
                // 标题和时间
                VStack(spacing: 5) {
                    Text("Payment Successful")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("13th May, 2025 07:30pm")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                // 商品列表
                VStack(spacing: 8) {
                    ReceiptItem(name: "1x Bowl of Chicken", price: "₦8,000.00")
                    ReceiptItem(name: "1x Can Diet Coke", price: "₦900.00")
                    ReceiptItem(name: "1x Fried Rice", price: "₦1,800.00")
                }
                .padding(.bottom, 15)
                
                // 小计、税费和服务费
                VStack(spacing: 8) {
                    ReceiptItem(name: "Subtotal", price: "₦10,700.00")
                    ReceiptItem(name: "VAT (9%)", price: "₦963.00")
                    ReceiptItem(name: "Service Fee", price: "₦2,000.00")
                }
                .padding(.bottom, 15)
                
                // 总计
                HStack {
                    Text("TOTAL")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("₦13,663.00")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                }
                .padding(.bottom, 15)
                
                // 感谢信息
                HStack {
                    Spacer()
                    Image(systemName: "hands.clap.fill")
                        .foregroundColor(.yellow)
                    Text("THANK YOU")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: 270) // 限制内容的最大宽度
            .background(Color.white)
            
            // 锯齿边缘
            ZigzagEdge()
                .fill(Color.white)
                .frame(height: 20)
        }
        .frame(width: 300) // 设置收据纸张的宽度
        .background(Color.white)
        .cornerRadius(2)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// 收据项目组件
struct ReceiptItem: View {
    let name: String
    let price: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(price)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
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
