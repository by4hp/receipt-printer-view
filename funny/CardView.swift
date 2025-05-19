//
//  CardView.swift
//  funny
//
//  Created by Cascade on 2025/5/19.
//

import SwiftUI

// 卡片状态枚举
enum CardState {
    case stacked    // 堆叠状态
    case exploded   // 爆炸展开状态
    case flipped    // 翻转状态
}

// 卡片数据模型
struct Card: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let author: String
    let frontGradient: [Color]
    let backGradient: [Color]
    let icon: String
}

struct CardView: View {
    // 示例卡片数据
    @State private var cards: [Card] = []
    
    // 用于接收重置信号
    @Binding var resetTrigger: Bool
    
    // 状态管理
    @State private var cardState: CardState = .stacked
    @State private var flippedCardIds: Set<UUID> = []
    @State private var isLongPressing: Bool = false
    @GestureState private var isLongPressingGesture: Bool = false
    @State private var explosionProgress: CGFloat = 0
    // 长按进度，用于控制卡片展开程度
    @State private var longPressProgress: CGFloat = 0
    @State private var focusedCardId: UUID? = nil
    // iOS长按菜单效果相关状态
    @State private var initialScaleEffect: Bool = false
    @State private var menuActivated: Bool = false
    
    // 用于生成随机位置
    @State private var cardOffsets: [UUID: CGPoint] = [:]
    @State private var cardRotations: [UUID: Double] = [:]
    
    // 屏幕尺寸
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                backgroundView
                
                // 卡片堆
                cardStackView(geometry: geometry)
                
                // 移除粒子效果
                
                // 提示文本
                instructionText
            }
            .onAppear {
                // 初始化卡片数据
                setupCards()
                // 初始化卡片位置和旋转角度
                initializeCardPositions()
            }
            .onChange(of: resetTrigger) { newValue in
                if newValue {
                    // 重置卡片堆
                    resetCardStack()
                }
            }
        }
    }
    
    // 背景视图
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color(hex: "121214") : Color(hex: "F2F2F7"),
                colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "FFFFFF")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // 指引文本
    private var instructionText: some View {
        VStack {
            Spacer()
            
            Text(cardState == .stacked ? "长按抽取卡片" : "点击卡片查看详情")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
                .background(Material.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.bottom, 30)
        }
    }
    
    // 卡片堆视图
    private func cardStackView(geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        return ZStack {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                let isFlipped = flippedCardIds.contains(card.id)
                
                SingleCardView(
                    card: card,
                    isFlipped: isFlipped,
                    cardState: cardState,
                    geometry: geometry
                )
                .offset(
                    x: getCardXOffset(card: card, index: index, geometry: geometry),
                    y: getCardYOffset(card: card, index: index, geometry: geometry)
                )
                .rotationEffect(
                    .degrees(
                        getCardRotation(card: card, index: index)
                    )
                )
                .scaleEffect(
                    cardState == .stacked ? 1 - CGFloat(index) * 0.015 : 1
                )
                .zIndex(
                    cardState == .stacked ? Double(cards.count - index) : 
                    isFlipped ? 100 : Double(cards.count - index)
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: cardState)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isFlipped)
                .onTapGesture {
                    if cardState == .exploded {
                        // 触发卡片翻转和聚焦
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            if flippedCardIds.contains(card.id) {
                                // 如果卡片已翻转，则取消翻转并取消聚焦
                                flippedCardIds.remove(card.id)
                                focusedCardId = nil
                            } else {
                                // 翻转卡片并聚焦
                                flippedCardIds.insert(card.id)
                                focusedCardId = card.id
                                // 触发轻微震动
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                }
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        // 添加长按手势与视觉反馈
        .gesture(
            // 使用DragGesture来捕捉长按过程中的时间变化
            DragGesture(minimumDistance: 0)
                .updating($isLongPressingGesture) { _, state, _ in
                    // 当手指按下时设置为true
                    state = true
                }
                .onChanged { _ in
                    // 当手指按下时更新状态
                    if cardState == .stacked {
                        if !isLongPressing {
                            // 模拟IOS长按菜单效果：先有一个快速的初始缩放
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                initialScaleEffect = true
                                isLongPressing = true
                            }
                            
                            // 初次按下时的轻微震动反馈（类似触觉引擎）
                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                            generator.prepare() // 预先准备震动引擎
                            generator.impactOccurred(intensity: 0.3)
                            
                            // 开始展开动画定时器
                            startExpandAnimation(geometry: geometry)
                            
                            // 延迟触发菜单激活效果（模拟IOS菜单弹出前的延迟）
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if isLongPressing {
                                    // 菜单激活时的强烈震动（类似菜单弹出）
                                    let activationGenerator = UIImpactFeedbackGenerator(style: .heavy)
                                    activationGenerator.impactOccurred(intensity: 0.8)
                                    
                                    // 激活菜单效果
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) {
                                        menuActivated = true
                                    }
                                }
                            }
                        }
                    }
                }
                .onEnded { _ in
                    // 手指松开时
                    isLongPressing = false
                    
                    // 重置菜单效果相关状态
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        initialScaleEffect = false
                        menuActivated = false
                    }
                    
                    if cardState == .stacked {
                        // 如果展开进度足够，完成展开
                        if longPressProgress > 0.5 {
                            completeExpansion()
                        } else {
                            // 否则取消展开
                            cancelExpansion()
                        }
                    }
                }
        )
        // 添加iOS长按菜单效果的视觉反馈
        .scaleEffect(getScaleEffect())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLongPressingGesture)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLongPressing)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: initialScaleEffect)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: menuActivated)
    }
    
    // 粒子效果已移除
    
    // 获取iOS风格的长按缩放效果
    private func getScaleEffect() -> CGFloat {
        if menuActivated {
            // 菜单激活后，卡片缩放到的大小（类似iOS长按菜单弹出时的大小）
            return 0.92
        } else if initialScaleEffect {
            // 初始按下时的缩放效果（类似iOS长按初始缩放）
            return 0.96
        } else if isLongPressingGesture || isLongPressing {
            // 普通按下状态
            return 0.98
        }
        // 默认状态
        return 1.0
    }
    
    // 初始化卡片数据 - 世界边角冷知识卡
    private func setupCards() {
        // 格陵兰书村
        let greenlandCard = Card(
            title: "格陵兰书村",
            description: "格陵兰有一座小村庄伊特托克托克，全村只有2人，他们管理着世界上最北的图书馆。",
            author: "北极圈边缘",
            frontGradient: [Color(hex: "64D2FF"), Color(hex: "30D158")],
            backGradient: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
            icon: "book.closed.fill"
        )
        
        // 不与世界接触的部落
        let sentinelCard = Card(
            title: "哥伦比亚哥德部落",
            description: "哥伦比亚亚马逊雨林中的哥德部落是地球上最后一个与现代文明完全隔绝的原始部落，他们拒绝与外界接触。",
            author: "亚马逊深处",
            frontGradient: [Color(hex: "FF9F0A"), Color(hex: "FF375F")],
            backGradient: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
            icon: "person.crop.circle.badge.exclamationmark"
        )
        
        // 没有老鼠的岛屿
        let mouseCard = Card(
            title: "无鼠岛屿",
            description: "阿尔伯塔的马克卡里岛是世界上唯一没有老鼠的地方，岛上有特殊的蛇类捕食者保护生态系统。",
            author: "南半球秘境",
            frontGradient: [Color(hex: "5E5CE6"), Color(hex: "BF5AF2")],
            backGradient: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
            icon: "ladybug.fill"
        )
        
        // 永恒之火
        let fireCard = Card(
            title: "阿塞拜疆永恒之火",
            description: "阿塞拜疆有一处被称为‘亚纳尔达格’的地方，那里的天然气火焰已经连续燃烧4000多年，被称为‘永恒之火’。",
            author: "中亚火山带",
            frontGradient: [Color(hex: "FF375F"), Color(hex: "FF9F0A")],
            backGradient: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
            icon: "flame.fill"
        )
        
        // 岛上国家
        let islandCard = Card(
            title: "海上微型国家",
            description: "西兰公国是一个建立在北海平台上的微型国家，面积只有4000平方米，人口不到2人，有自己的货币和邮票。",
            author: "海洋微国志",
            frontGradient: [Color(hex: "30D158"), Color(hex: "64D2FF")],
            backGradient: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
            icon: "island"
        )
        
        // 将卡片添加到数组中
        cards = [greenlandCard, sentinelCard, mouseCard, fireCard, islandCard]
    }
    
    // 初始化卡片位置
    private func initializeCardPositions() {
        for card in cards {
            // 随机生成爆炸后的位置 - 增加距离范围
            let randomAngle = Double.random(in: 0..<360)
            let randomDistance = CGFloat.random(in: 150...300) // 增加距离范围
            let offsetX = cos(randomAngle * .pi / 180) * randomDistance
            let offsetY = sin(randomAngle * .pi / 180) * randomDistance
            
            cardOffsets[card.id] = CGPoint(x: offsetX, y: offsetY)
            cardRotations[card.id] = Double.random(in: -45...45) // 增加旋转角度范围
        }
    }
    
    // 存储展开定时器
    @State private var expansionTimer: Timer? = nil
    
    // 开始展开动画
    private func startExpandAnimation(geometry: GeometryProxy) {
        // 初始化展开进度
        longPressProgress = 0
        
        // 停止现有定时器
        stopExpansionTimer()
        
        // 创建定时器，每帧增加展开进度
        expansionTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateExpansion()
        }
        
        // 轻微震动反馈
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
    }
    
    // 更新展开进度 - 模拟iOS长按菜单效果
    private func updateExpansion() {
        // 只有在长按时才增加进度
        if isLongPressing && cardState == .stacked {
            // 如果菜单已激活，使用更快的展开速度
            let progressIncrement = menuActivated ? 0.08 : 0.05
            
            // 逐渐增加展开进度
            longPressProgress += progressIncrement
            
            // 限制最大值
            longPressProgress = min(longPressProgress, 1.0)
            
            // 更新展开效果 - 使用更自然的弹簧动画
            let animationDuration = menuActivated ? 0.2 : 0.1
            withAnimation(.spring(response: animationDuration, dampingFraction: 0.7)) {
                explosionProgress = longPressProgress
                
                // 当进度超过50%时切换到展开状态
                if longPressProgress >= 0.5 && cardState == .stacked {
                    cardState = .exploded
                    
                    // 使用触觉引擎提供更真实的震动反馈
                    let notificationGenerator = UINotificationFeedbackGenerator()
                    notificationGenerator.notificationOccurred(.success)
                    
                    // 紧接着再来一次中等震动，增强效果
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
                    }
                }
            }
            
            // 在特定进度点添加震动反馈 - 使用更精细的震动模式
            if menuActivated {
                // 菜单激活后的震动模式
                if longPressProgress >= 0.6 && longPressProgress < 0.62 {
                    // 使用触觉引擎的选择反馈
                    UISelectionFeedbackGenerator().selectionChanged()
                } else if longPressProgress >= 0.85 && longPressProgress < 0.87 {
                    // 使用震动反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.5)
                }
            } else {
                // 菜单激活前的震动模式
                if longPressProgress >= 0.25 && longPressProgress < 0.27 {
                    UISelectionFeedbackGenerator().selectionChanged()
                } else if longPressProgress >= 0.4 && longPressProgress < 0.42 {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
                }
            }
        } else {
            // 停止定时器
            stopExpansionTimer()
        }
    }
    
    // 完成展开
    private func completeExpansion() {
        // 停止定时器
        stopExpansionTimer()
        
        // 完成展开动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            cardState = .exploded
            explosionProgress = 1.0
        }
        
        // 完成震动反馈
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.8)
    }
    
    // 取消展开
    private func cancelExpansion() {
        // 停止定时器
        stopExpansionTimer()
        
        // 返回堆叠状态
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            cardState = .stacked
            explosionProgress = 0
        }
    }
    
    // 停止展开定时器
    private func stopExpansionTimer() {
        // 停止并释放定时器
        expansionTimer?.invalidate()
        expansionTimer = nil
    }
    
    // 获取卡片X轴偏移量
    private func getCardXOffset(card: Card, index: Int, geometry: GeometryProxy) -> CGFloat {
        // 如果是聚焦卡片，移动到屏幕中心
        if focusedCardId == card.id {
            return 0 // 屏幕中心
        }
        
        // 堆叠状态
        if cardState == .stacked {
            return CGFloat(index) * 3.0
        }
        
        // 爆炸状态
        return (cardOffsets[card.id]?.x ?? 0) * explosionProgress
    }
    
    // 获取卡片Y轴偏移量
    private func getCardYOffset(card: Card, index: Int, geometry: GeometryProxy) -> CGFloat {
        // 如果是聚焦卡片，移动到屏幕中心
        if focusedCardId == card.id {
            return 0 // 屏幕中心
        }
        
        // 堆叠状态
        if cardState == .stacked {
            return CGFloat(index) * 2.0
        }
        
        // 爆炸状态
        return (cardOffsets[card.id]?.y ?? 0) * explosionProgress
    }
    
    // 获取卡片旋转角度
    private func getCardRotation(card: Card, index: Int) -> Double {
        // 如果是聚焦卡片，保持水平
        if focusedCardId == card.id {
            return 0
        }
        
        // 堆叠状态
        if cardState == .stacked {
            return Double(index) * 2.0
        }
        
        // 爆炸状态
        return (cardRotations[card.id] ?? 0) * explosionProgress
    }
    
    // 重置卡片堆
    private func resetCardStack() {
        // 添加动画效果
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            // 重置卡片状态
            cardState = .stacked
            flippedCardIds.removeAll()
            focusedCardId = nil
            explosionProgress = 0
        }
        
        // 触发震动反馈
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 重置完成后将触发器设置回 false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            resetTrigger = false
        }
    }
}

// 单张卡片视图
struct SingleCardView: View {
    let card: Card
    let isFlipped: Bool
    let cardState: CardState
    let geometry: GeometryProxy
    
    // 翻转动画状态
    @State private var rotation3D: Double = 0
    
    var body: some View {
        ZStack {
            // 卡片背面
            cardBack
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // 卡片正面
            cardFront
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: cardWidth, height: cardHeight)
        .shadow(
            color: isFlipped ? 
                card.frontGradient.first!.opacity(0.5) : 
                Color.black.opacity(0.2),
            radius: isFlipped ? 15 : 5,
            x: 0,
            y: 5
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isFlipped)
    }
    
    // 卡片宽度
    private var cardWidth: CGFloat {
        min(geometry.size.width * 0.8, 300)
    }
    
    // 卡片高度
    private var cardHeight: CGFloat {
        cardWidth * 1.5
    }
    
    // 卡片背面
    private var cardBack: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: card.backGradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 内边框
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.4), .white.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                // 增强内边框效果，代替四角装饰
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            lineWidth: 0.8
                        )
                        .padding(3)
                )
            
            // 背面图案
            VStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.1))
                
                Text("?")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.15))
            }
            
            // 神秘符号
            VStack {
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.bottom, 10)
            }
            .padding()
        }
    }
    
    // 卡片正面
    private var cardFront: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: card.frontGradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 光泽效果
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        .white.opacity(0.5),
                                        .clear,
                                        .clear
                                    ]
                                ),
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: 16)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // 卡片内容
            VStack(spacing: 15) {
                // 图标区域
                ZStack {
                    // 背景光晕效果
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .blur(radius: 8)
                    
                    // 图标背景
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 85, height: 85)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    // 内圈装饰
                    Circle()
                        .strokeBorder(LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1.5)
                        .frame(width: 75, height: 75)
                    
                    // 图标
                    Image(systemName: card.icon)
                        .font(.system(size: 42, weight: .light))
                        .foregroundColor(.white)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .padding(.top, 25)
                
                Spacer()
                
                // 标题和描述
                VStack(spacing: 12) {
                    Text(card.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Text(card.description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
                
                // 作者信息
                Text("— " + card.author)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.8))
                    .italic()
                    .padding(.bottom, 25)
            }
            
            // 装饰性图案
            ZStack {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 10...30))
                        .position(
                            x: CGFloat.random(in: 0...cardWidth),
                            y: CGFloat.random(in: 0...cardHeight)
                        )
                }
            }
            .mask(
                RoundedRectangle(cornerRadius: 16)
            )
        }
    }
}


#Preview {
    CardView(resetTrigger: .constant(false))
}