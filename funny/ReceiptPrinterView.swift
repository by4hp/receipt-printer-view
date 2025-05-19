//
//  ReceiptPrinterView.swift
//  funny
//
//  Created by Cascade on 2025/5/15.
//

import SwiftUI
import CoreHaptics

// 收据数据模型
struct ReceiptData: Identifiable {
    var id = UUID()
    var title: String
    var date: Date
    var items: [ReceiptItemData]
    var total: Double
    var quote: String
    var author: String
    
    // 生成随机收据
    static func random() -> ReceiptData {
        // 随机标题
        let titles = ["日常消费", "工作费用", "创意项目", "技术学习", "生活体验"]
        
        // 随机项目
        let allItems = [
            ReceiptItemData(name: "SwiftUI 设计", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "UI 动画实现", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "高级手势处理", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "震动反馈集成", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "组件化开发", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "数据流管理", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "手势交互设计", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "定制动画效果", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "界面原型设计", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "用户体验优化", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "性能调优分析", price: Double.random(in: 99...399)),
            ReceiptItemData(name: "设计系统集成", price: Double.random(in: 99...399))
        ]
        
        // 随机选择 2-5 个项目
        let itemCount = Int.random(in: 2...5)
        let selectedItems = Array(allItems.shuffled().prefix(itemCount))
        
        // 计算总价
        let total = selectedItems.reduce(0) { $0 + $1.price }
        
        // 随机名言
        let quotes = [
            "保持简约，专注本质",
            "设计就是如何工作的",
            "创新来自于不同角度的思考",
            "简单比复杂更难",
            "细节决定成败",
            "每一个像素都很重要"
        ]
        
        return ReceiptData(
            title: titles.randomElement() ?? "随机收据",
            date: Date(),
            items: selectedItems,
            total: total,
            quote: quotes.randomElement() ?? "保持简约，专注本质",
            author: "Steve Jobs"
        )
    }
    
    static var sample: ReceiptData {
        ReceiptData(
            title: "收据打印演示",
            date: Date(),
            items: [
                ReceiptItemData(name: "SwiftUI 设计", price: 199.00),
                ReceiptItemData(name: "UI 动画实现", price: 299.00),
                ReceiptItemData(name: "高级手势处理", price: 159.00),
                ReceiptItemData(name: "震动反馈集成", price: 99.00)
            ],
            total: 756.00,
            quote: "保持简约，专注本质",
            author: "Steve Jobs"
        )
    }
    
    static var sample2: ReceiptData {
        ReceiptData(
            title: "新的收据样例",
            date: Date(),
            items: [
                ReceiptItemData(name: "组件化开发", price: 259.00),
                ReceiptItemData(name: "数据流管理", price: 359.00),
                ReceiptItemData(name: "手势交互设计", price: 189.00)
            ],
            total: 807.00,
            quote: "设计就是如何工作的",
            author: "Steve Jobs"
        )
    }
}

// 收据项目数据模型
struct ReceiptItemData {
    var name: String
    var price: Double
}

struct ReceiptPrinterView: View {
    // 收据状态枚举
    enum ReceiptState {
        case notPrinted       // 未打印
        case printing        // 打印中
        case printed         // 已打印
        case completed       // 已完成（仅用于多收据场景）
    }
    
    // 添加状态变量来控制收据的显示状态
    @State private var receiptOffset: CGFloat = -500 // 初始默认值，会被实际计算值替换
    @State private var isBlinking: Bool = false
    @State private var receiptState: ReceiptState = .notPrinted
    @State private var dragOffset: CGFloat = 0
    @State private var currentReceiptIndex: Int = 0
    @State private var isDragging: Bool = false
    @State private var isLongPressed: Bool = false // 长按状态
    @State private var showFullReceipt: Bool = false // 是否显示全屏收据
    @State private var engine: CHHapticEngine?
    @State private var receiptHeight: CGFloat = 0 // 存储收据的实际高度
    @State private var printingProgress: CGFloat = 0 // 打印进度 (0-1)
    @State private var printingSpeed: CGFloat = 1.0 // 打印速度倍率
    @State private var printingTimer: Timer? = nil // 打印计时器
    @State private var visibleReceipts: [VisibleReceipt] = [] // 当前可见的收据列表
    
    // 可见收据结构体，用于管理多张收据的状态
    struct VisibleReceipt: Identifiable {
        var id = UUID()
        var data: ReceiptData
        var state: ReceiptState
        var offset: CGFloat
        var dragOffset: CGFloat = 0
        var zIndex: Double
        
        // 计算总偏移量
        var totalOffset: CGFloat {
            return offset + dragOffset
        }
    }
    
    // 收据数据数组
    @State private var receipts: [ReceiptData] = [ReceiptData.sample, ReceiptData.sample2]
    
    // 添加一个方法来生成新的收据
    private func generateNewReceipt() {
        let newReceipt = ReceiptData.random()
        receipts.append(newReceipt)
    }
    
    // 初始化可见收据
    private func initializeVisibleReceipts() {
        guard !receipts.isEmpty else { return }
        
        // 初始化第一张收据
        let initialReceipt = VisibleReceipt(
            data: receipts[0],
            state: .notPrinted,
            offset: initialReceiptOffset,
            zIndex: 1.0
        )
        
        visibleReceipts = [initialReceipt]
    }
    
    // 开始打印当前收据
    private func startPrinting() {
        guard !visibleReceipts.isEmpty else { return }
        
        // 获取当前收据索引
        guard let currentIndex = visibleReceipts.firstIndex(where: { $0.state == .notPrinted }) else { return }
        
        // 开始闪烁状态灯
        withAnimation(.linear(duration: 0.3).repeatForever()) {
            isBlinking = true
        }
        
        // 初始震动
        simpleSuccess()
        
        // 更新状态
        visibleReceipts[currentIndex].state = .printing
        printingProgress = 0
        printingSpeed = 1.0
        
        // 创建定时器模拟打印过程
        printingTimer?.invalidate()
        printingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] timer in
            // 根据速度增加打印进度
            printingProgress += 0.005 * printingSpeed
            
            // 计算偏移量
            let newOffset = initialReceiptOffset + (receiptHeight + initialReceiptOffset) * printingProgress
            
            // 更新收据偏移量
            withAnimation(.linear(duration: 0.05)) {
                visibleReceipts[currentIndex].offset = newOffset
            }
            
            // 根据打印进度触发震动
            if Int(printingProgress * 100) % 10 == 0 {
                if printingProgress < 0.3 {
                    simpleSuccess() // 开始时轻微震动
                } else if printingProgress < 0.8 {
                    // 中间过程中等强度震动
                    if Int(printingProgress * 100) % 20 == 0 {
                        mediumSuccess()
                    } else {
                        simpleSuccess()
                    }
                } else {
                    // 结束时较强震动
                    mediumSuccess()
                }
            }
            
            // 打印完成
            if printingProgress >= 1.0 {
                timer.invalidate()
                printingTimer = nil
                complexSuccess()
                
                // 更新状态
                visibleReceipts[currentIndex].state = .printed
                
                // 停止闪烁
                withAnimation {
                    isBlinking = false
                }
            }
        }
    }
    
    // 加速打印
    private func speedUpPrinting() {
        // 增加打印速度
        printingSpeed = 3.0
        mediumSuccess()
    }
    
    // 添加新收据
    private func addNewReceipt() {
        // 确保有收据可用
        if currentReceiptIndex >= receipts.count - 1 {
            generateNewReceipt()
        }
        
        // 获取下一张收据
        let nextIndex = currentReceiptIndex + 1
        currentReceiptIndex = nextIndex
        
        // 创建新收据
        let newReceipt = VisibleReceipt(
            data: receipts[nextIndex],
            state: .notPrinted,
            offset: initialReceiptOffset,
            zIndex: 0.0 // 初始化为较低的z索引
        )
        
        // 将当前收据的z索引提高
        for i in 0..<visibleReceipts.count {
            visibleReceipts[i].zIndex += 1
        }
        
        // 添加新收据
        visibleReceipts.append(newReceipt)
    }
    
    // 计算初始偏移量（隐藏4/5的高度）
    private var initialReceiptOffset: CGFloat {
        if receiptHeight == 0 {
            return -500 // 默认值，当高度还未测量时使用
        }
        return -receiptHeight * 4/5 // 向上偏移收据高度的4/5
    }
    
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
        ZStack(alignment: .top) {
            // 打印机头部 - 灰色金属质感，有立体阴影，始终固定在顶部
            VStack {
                PrinterHead(isBlinking: isBlinking)
                    .onTapGesture(count: 1, perform: {
                        // 查找当前正在打印或未打印的收据
                        if let printingIndex = visibleReceipts.firstIndex(where: { $0.state == .printing }) {
                            // 如果有收据正在打印，点击打印机会加速打印
                            speedUpPrinting()
                        } else if let _ = visibleReceipts.firstIndex(where: { $0.state == .notPrinted }) {
                            // 如果有未打印的收据，开始打印
                            startPrinting()
                        } else if visibleReceipts.allSatisfy({ $0.state == .printed || $0.state == .completed }) {
                            // 如果所有收据都已打印完成，添加新收据
                            addNewReceipt()
                            // 延迟一小段时间后开始打印新收据
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                startPrinting()
                            }
                        }
                    })
                
                Spacer() // 使打印机始终保持在顶部
            }
            .zIndex(1) // 打印机头部在中间层
            
            // 收据纸张 - 放在最上层
            // 创建一个裁剪区域，只显示出纸口下方的部分
            ZStack(alignment: .top) {
                // 显示所有可见收据
                ZStack {
                    ForEach(visibleReceipts) { receipt in
                        ReceiptPaper(
                            receiptData: receipt.data,
                            onHeightChanged: { height in
                                if receiptHeight == 0 {
                                    print("收据实际高度: \(height)")
                                    DispatchQueue.main.async {
                                        self.receiptHeight = height
                                        // 初始化所有收据的偏移量
                                        if visibleReceipts.isEmpty {
                                            initializeVisibleReceipts()
                                        }
                                    }
                                }
                            }
                        )
                        .padding(.bottom, 100)
                        .frame(maxWidth: .infinity)
                        .offset(y: receipt.totalOffset)
                        .zIndex(receipt.zIndex)
                        // 添加长按手势
                        .onLongPressGesture(minimumDuration: 0.5) {
                            if receipt.state == .printed {
                                withAnimation(.spring()) {
                                    showFullReceipt = true
                                }
                                mediumSuccess() // 触发震动反馈
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    isDragging = true
                                    // 找到当前收据的索引
                                    if let index = visibleReceipts.firstIndex(where: { $0.id == receipt.id }) {
                                        // 直接使用拖动的位移量，不限制范围
                                        visibleReceipts[index].dragOffset = gesture.translation.height
                                        
                                        // 如果正在打印，暂停打印
                                        if receipt.state == .printing {
                                            printingTimer?.invalidate()
                                            printingTimer = nil
                                        }
                                    }
                                }
                                .onEnded { gesture in
                                    isDragging = false
                                    
                                    // 找到当前收据的索引
                                    guard let index = visibleReceipts.firstIndex(where: { $0.id == receipt.id }) else { return }
                                    
                                    // 根据收据状态和拖动距离处理不同情况
                                    switch visibleReceipts[index].state {
                                    case .notPrinted, .printing:
                                        // 未打印或打印中的收据拖动处理
                                        let dragDistance = gesture.translation.height
                                        let halfReceiptHeight = receiptHeight / 2
                                        
                                        if dragDistance > halfReceiptHeight {
                                            // 拖动距离超过收据长度的一半，设置为已打印状态
                                            withAnimation(.spring()) {
                                                visibleReceipts[index].state = .printed
                                                visibleReceipts[index].dragOffset = 0
                                                visibleReceipts[index].offset = 0 // 完全显示收据
                                                isBlinking = true
                                            }
                                            
                                            // 模拟打印完成后的震动和闪烁停止
                                            mediumSuccess()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                withAnimation {
                                                    isBlinking = false
                                                }
                                            }
                                        } else {
                                            // 拖动距离不足，返回未打印状态
                                            withAnimation(.spring()) {
                                                visibleReceipts[index].state = .notPrinted
                                                visibleReceipts[index].dragOffset = 0
                                                visibleReceipts[index].offset = initialReceiptOffset
                                            }
                                            simpleSuccess()
                                        }
                                        
                                    case .printed:
                                        // 已打印收据的拖动处理
                                        let dragDistance = gesture.translation.height
                                        let loadNewThreshold = receiptHeight + 120 // 加载新收据的阈值
                                        
                                        if dragDistance > loadNewThreshold {
                                            // 如果拖动距离足够大，加载新收据
                                            // 查找是否已有第二张收据
                                            if visibleReceipts.count > 1 {
                                                let secondReceiptIndex = (index + 1) % visibleReceipts.count
                                                let secondReceiptDragDistance = dragDistance - loadNewThreshold
                                                let halfSecondReceiptHeight = receiptHeight / 2
                                                
                                                if secondReceiptDragDistance > halfSecondReceiptHeight {
                                                    // 第二张收据拖动足够，第一张收据完成，第二张变为已打印
                                                    withAnimation(.spring()) {
                                                        visibleReceipts[index].state = .completed
                                                        visibleReceipts[index].dragOffset = 0
                                                        visibleReceipts[index].offset = -receiptHeight // 移出屏幕
                                                        
                                                        visibleReceipts[secondReceiptIndex].state = .printed
                                                        visibleReceipts[secondReceiptIndex].dragOffset = 0
                                                        visibleReceipts[secondReceiptIndex].offset = 0
                                                    }
                                                    mediumSuccess()
                                                } else {
                                                    // 第二张收据拖动不足，回弹到第一张已打印状态
                                                    withAnimation(.spring()) {
                                                        visibleReceipts[index].dragOffset = 0
                                                        visibleReceipts[secondReceiptIndex].dragOffset = 0
                                                    }
                                                    simpleSuccess()
                                                }
                                            } else {
                                                // 没有第二张收据，添加新收据
                                                addNewReceipt()
                                                withAnimation(.spring()) {
                                                    visibleReceipts[index].dragOffset = 0
                                                }
                                                mediumSuccess()
                                            }
                                        } else {
                                            // 拖动距离不足，回弹
                                            withAnimation(.spring()) {
                                                visibleReceipts[index].dragOffset = 0
                                            }
                                        }
                                        
                                    case .completed:
                                        // 已完成收据不处理拖动
                                        withAnimation(.spring()) {
                                            visibleReceipts[index].dragOffset = 0
                                        }
                                    }
                                }
                        )
                    }
                }
            }
            // .frame(width: 350)
            .clipped()
            .offset(y: 105)
            // .mask(
            //     Rectangle()
            //         .frame(width: 350, height: 700)
            //         .offset(y: 25) // 相对于出纸口位置下移20点
            // )
            .zIndex(3)
            .allowsHitTesting(true) // 允许所有状态下都可以交互
        }
        .frame(maxWidth: 350)
        .onAppear {
            prepareHaptics()
            // 如果收据高度已知但可见收据列表为空，初始化收据
            if receiptHeight > 0 && visibleReceipts.isEmpty {
                initializeVisibleReceipts()
            }
        }
        .overlay(
            // 调试信息，显示初始偏移量和收据高度
            VStack {
                Spacer()
                Text("偏移量: \(Int(initialReceiptOffset))")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(4)
                Text("收据高度: \(Int(receiptHeight))")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(4)
            }
            .padding(.bottom, 10)
            , alignment: .bottom
        )
        // 全屏收据视图
        .fullScreenCover(isPresented: $showFullReceipt, content: {
            ZStack {
                // 半透明背景
                Color.black.opacity(0.5) // 降低不透明度以增强半透明效果
                    .ignoresSafeArea()
                
                // 收据内容
                VStack {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            showFullReceipt = false
                            simpleSuccess() // 简单震动反馈
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    
                    // 收据内容
                    ScrollView {
                        // 显示当前活跃的收据
                        if let activeReceipt = visibleReceipts.first(where: { $0.state == .printed }) {
                            ReceiptPaper(receiptData: activeReceipt.data, onHeightChanged: nil)
                                .frame(width: 320)
                                .padding()
                        } else if !visibleReceipts.isEmpty {
                            // 如果没有已打印的收据，显示第一张收据
                            ReceiptPaper(receiptData: visibleReceipts[0].data, onHeightChanged: nil)
                                .frame(width: 320)
                                .padding()
                        }
                    }
                    .padding(.bottom)
                }
                .transition(.move(edge: .bottom))
            }
            .animation(.spring(), value: showFullReceipt)
        })
    }
}

// 打印机头部组件
struct PrinterHead: View {
    var isBlinking: Bool
    var body: some View {
        ZStack(alignment: .top) {
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
                    .frame(height: 10)
                    .offset(y: 5)
                
            }
            .offset(y: 80) // 向下偏移，使其突出打印机头部
            
            // 打印机头部主体
            ZStack(alignment: .bottom) {
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
                .padding(.bottom, 10) // 添加右侧填充，使状态灯保持一定的距离
                // .offset(y:20)
            }
        }
    }
}

// 收据纸张组件
struct ReceiptPaper: View {
    // 收据数据
    var receiptData: ReceiptData
    // 添加一个回调函数来传递高度
    var onHeightChanged: ((CGFloat) -> Void)? = nil
    
    // 格式化日期
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // 格式化价格
    func formattedPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        return formatter.string(from: NSNumber(value: price)) ?? "¥\(price)"
    }
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                // 收据标题
                HStack {
                    Spacer()
                    Text(receiptData.title)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.bottom, 5)
                
                // 日期和时间
                HStack {
                    Spacer()
                    Text(formattedDate(date: receiptData.date))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // 收据项目
                VStack(alignment: .leading, spacing: 8) {
                    // 收据项目标题
                    HStack {
                        Text("项目")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                        Spacer()
                        Text("价格")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .padding(.bottom, 5)
                    
                    // 收据项目列表
                    ForEach(receiptData.items.indices, id: \.self) { index in
                        let item = receiptData.items[index]
                        ReceiptItem(
                            name: item.name,
                            price: formattedPrice(item.price)
                        )
                    }
                }
                .padding(.vertical, 10)
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // 总计
                HStack {
                    Text("总计")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text(formattedPrice(receiptData.total))
                        .font(.system(size: 15, weight: .bold))
                }
                .padding(.vertical, 5)
                
                // 分隔线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // 名言
                HStack {
                    Spacer()
                    Text("“\(receiptData.quote)”")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                }
                .padding(.vertical, 10)
                
                // 签名
                HStack {
                    Spacer()
                    Text("— \(receiptData.author)")
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
        .frame(maxWidth: 300) // 设置收据纸张的宽度
        .background(Color(hex: "F1EFEF"))
        .cornerRadius(2)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        // 在视图出现时传递高度信息
                        onHeightChanged?(geometry.size.height)
                    }
            }
        )
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
