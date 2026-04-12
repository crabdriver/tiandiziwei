// ZiWeiChartView.swift - 紫微盘面视图
// 看盘啦 · iOS 紫微斗数排盘（SwiftUI Canvas）

import SwiftUI
import AudioToolbox

/// 紫微排盘盘面视图
struct ZiWeiChartView: View {
    let chart: ZiWeiChart

    /// 用于 `.sheet(item:)` 的轻量标识
    private struct PresentedPalace: Identifiable {
        let id: Int
    }

    @State private var presentedPalaceSheet: PresentedPalace?
    
    /// 当选中的地支索引（用于文墨天机同款的三方四正连线），默认打开时取命宫
    @State private var selectedZhiIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let cellWidth = (w - 1.5) / 4
            let cellHeight = (h - 1.5) / 4
            let minScale = min(cellWidth, cellHeight)
            
            ZStack {
                // 盘面底色
                ZiWeiColors.chartPaper
                
                // 十二宫格 (通过 spacing 产生 0.5px 的网格线)
                VStack(spacing: 0.5) {
                    // 第一行: 巳 午 未 申 (索引: 5,6,7,8)
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(5), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        palaceCell(atIndex: positionToIndex(6), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        palaceCell(atIndex: positionToIndex(7), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        palaceCell(atIndex: positionToIndex(8), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                    }
                    
                    // 第二行: 辰 [中央] [中央] 酉
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(4), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        
                        // 中央区域上半
                        centerView(scale: minScale)
                            .frame(width: cellWidth * 2 + 0.5, height: cellHeight)
                            .background(ZiWeiColors.chartPaper)
                        
                        palaceCell(atIndex: positionToIndex(9), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                    }
                    
                    // 第三行: 卯 [中央] [中央] 戌
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(3), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        
                        // 中央区域下半
                        centerViewBottom(scale: minScale)
                            .frame(width: cellWidth * 2 + 0.5, height: cellHeight)
                            .background(ZiWeiColors.chartPaper)
                        
                        palaceCell(atIndex: positionToIndex(10), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                    }
                    
                    // 第四行: 寅 丑 子 亥 (索引: 2,1,0,11)
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(2), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        palaceCell(atIndex: positionToIndex(1), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        palaceCell(atIndex: positionToIndex(0), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                        palaceCell(atIndex: positionToIndex(11), cellWidth: cellWidth, cellHeight: cellHeight, scale: minScale)
                    }
                }
                .background(ZiWeiColors.border) // 网格线颜色
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(ZiWeiColors.chartFrame.opacity(0.9), lineWidth: 1)
                )
                
                // 三方四正连线层（复刻飞线交互）
                if let zhiIdx = selectedZhiIndex {
                    drawSanFangSiZhengLines(for: zhiIdx, cellWidth: cellWidth, cellHeight: cellHeight, gap: 0.5)
                }
            }
            .frame(width: w, height: h)
        }
        .onAppear {
            if selectedZhiIndex == nil {
                // 初始化时默认选中命宫
                if let ming = chart.palaces.first(where: { $0.name == "命宫" }),
                   let idx = diZhi.firstIndex(of: ming.position) {
                    selectedZhiIndex = idx
                }
            }
        }
        .sheet(item: $presentedPalaceSheet) { item in
            NavigationStack {
                ScrollView {
                    if item.id < chart.palaces.count {
                        PalaceDetailContent(palace: chart.palaces[item.id])
                            .padding(16)
                    }
                }
                .ziWeiInputBackdrop()
                .navigationTitle(item.id < chart.palaces.count ? chart.palaces[item.id].name : "宫位")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") {
                            presentedPalaceSheet = nil
                        }
                    }
                }
            }
        }
    }

    /// 将地支索引转换为宫的索引
    private func positionToIndex(_ zhiIdx: Int) -> Int? {
        chart.palaces.firstIndex(where: { $0.position == diZhi[zhiIdx] })
    }
    
    /// 单个宫格视图
    @ViewBuilder
    private func palaceCell(atIndex index: Int?, cellWidth: CGFloat, cellHeight: CGFloat, scale: CGFloat) -> some View {
        if let idx = index, idx < chart.palaces.count {
            let palace = chart.palaces[idx]
            let isMingGong = palace.name == "命宫"
            let isSelected = diZhi.firstIndex(of: palace.position) == selectedZhiIndex
            let markers = palaceMarkers(for: palace)
            
            ZStack {
                Rectangle()
                    .fill(isSelected ? ZiWeiColors.selectionFill : (isMingGong ? ZiWeiColors.mingGongHighlight : ZiWeiColors.chartPaper))
                    .overlay(
                        Rectangle().stroke(ZiWeiColors.selectionCyan, lineWidth: isSelected ? 1.5 : 0)
                    )

                if !markers.isEmpty {
                    VStack(alignment: .trailing, spacing: 1) {
                        ForEach(markers, id: \.self) { marker in
                            Text(marker)
                                .font(.system(size: scale * 0.10, weight: .bold)) // 放大
                                .foregroundColor(marker == "因" ? ZiWeiColors.huaJiColor : ZiWeiColors.huaQuanColor)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 3)
                    .padding(.trailing, 4)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    starsView(palace: palace, scale: scale, isSelected: isSelected)
                    
                    Spacer(minLength: 0)
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            if !palace.suiQian.isEmpty {
                                Text(palace.suiQian)
                                    .font(.system(size: scale * 0.07)) // 放大
                                    .foregroundColor(ZiWeiColors.zaYaoColor)
                            }
                            if !palace.jiangQian.isEmpty {
                                Text(palace.jiangQian)
                                    .font(.system(size: scale * 0.07))
                                    .foregroundColor(ZiWeiColors.zaYaoColor)
                            }
                            if !palace.boshi.isEmpty {
                                Text(palace.boshi)
                                    .font(.system(size: scale * 0.075))
                                    .foregroundColor(ZiWeiColors.zaYaoColor)
                            }
                        }
                        
                        Spacer(minLength: 0)
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            if !palace.daXian.isEmpty {
                                Text(palace.daXian)
                                    .font(.system(size: scale * 0.08)) // 放大
                                    .foregroundColor(ZiWeiColors.daXianColor)
                            }

                            if !palace.xiaoXian.isEmpty {
                                Text(palace.xiaoXian)
                                    .font(.system(size: scale * 0.075))
                                    .foregroundColor(ZiWeiColors.huaQuanColor)
                            }
                            
                            HStack(spacing: 1) {
                                Text(palace.tianGan)
                                    .font(.system(size: scale * 0.11, weight: .bold)) // 放大
                                    .foregroundColor(ZiWeiColors.textDark)
                                Text(palace.position)
                                    .font(.system(size: scale * 0.11, weight: .bold))
                                    .foregroundColor(ZiWeiColors.textDark)
                            }
                            
                            Text(palace.name)
                                .font(.system(size: scale * 0.10, weight: .bold)) // 放大
                                .foregroundColor(ZiWeiColors.gongNameColor)
                                .padding(.top, 1)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
                }
                .padding(2)
            }
            .frame(width: cellWidth, height: cellHeight)
            .accessibilityLabel("\(palace.name)，\(palace.tianGan)\(palace.position)")
            .accessibilityHint("打开详情")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                let targetZhiIdx = diZhi.firstIndex(of: palace.position)
                if selectedZhiIndex == targetZhiIdx {
                    presentedPalaceSheet = PresentedPalace(id: idx)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    AudioServicesPlaySystemSound(1104) // 系统按键音
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedZhiIndex = targetZhiIdx
                    }
                }
            }
        } else {
            Rectangle()
                .fill(ZiWeiColors.chartPaper)
                .frame(width: cellWidth, height: cellHeight)
        }
    }
    
    @ViewBuilder
    private func starsView(palace: Palace, scale: CGFloat, isSelected: Bool) -> some View {
        let zhengYaoSize = scale * 0.11
        let otherSize = scale * 0.09
        
        let zhengYao = palace.stars.filter { $0.category == .zhengYao }
        let others = palace.stars.filter { $0.category != .zhengYao }
        
        HStack(alignment: .top, spacing: 6) {
            if !zhengYao.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(zhengYao, id: \.name) { star in
                        starRow(star: star, fontSize: zhengYaoSize, isZhengYao: true, isSelected: isSelected)
                    }
                }
            }
            
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(others.prefix(5), id: \.name) { star in
                        starRow(star: star, fontSize: otherSize, isZhengYao: false, isSelected: isSelected)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func starRow(star: Star, fontSize: CGFloat, isZhengYao: Bool, isSelected: Bool) -> some View {
        HStack(spacing: 1) {
            Text(star.name)
                .font(.system(size: fontSize, weight: isZhengYao ? .bold : .medium))
                .foregroundColor(isSelected ? starColor(star) : ZiWeiColors.textMuted)
            
            if let brightness = star.brightness {
                Text(brightness)
                    .font(.system(size: fontSize * 0.8))
                    .foregroundColor(isSelected ? .gray : ZiWeiColors.textMuted.opacity(0.5))
            }
            
            if let hua = star.siHua {
                Text(huaShort(hua))
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundColor(isSelected ? huaColor(hua) : ZiWeiColors.textMuted)
                    .padding(.leading, 1)
            }
        }
    }
    
    @ViewBuilder
    private func centerView(scale: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text("看盘啦")
                .font(.system(size: scale * 0.16, weight: .bold, design: .serif))
                .foregroundColor(ZiWeiColors.textDark)
                .tracking(2)
            
            // 文墨天机式极简四柱
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("年").font(.system(size: scale * 0.06)).foregroundColor(.secondary)
                    Text(chart.lunarDate.yearGan + chart.lunarDate.yearZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
                VStack(spacing: 4) {
                    Text("月").font(.system(size: scale * 0.06)).foregroundColor(.secondary)
                    Text(chart.lunarDate.monthGan + chart.lunarDate.monthZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
                VStack(spacing: 4) {
                    Text("日").font(.system(size: scale * 0.06)).foregroundColor(.secondary)
                    Text(chart.lunarDate.dayGan + chart.lunarDate.dayZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
                VStack(spacing: 4) {
                    Text("时").font(.system(size: scale * 0.06)).foregroundColor(.secondary)
                    Text(chart.lunarDate.hourGan + chart.lunarDate.hourZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
            }
            .font(.system(size: scale * 0.12, weight: .bold)) // Bazi goes huge
        }
    }
    
    @ViewBuilder
    private func centerViewBottom(scale: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(chart.wuXingJu)
                .font(.system(size: scale * 0.11, weight: .heavy))
                .foregroundColor(ZiWeiColors.primary)
                .padding(.bottom, 2)

            HStack(spacing: 16) {
                Text("命主: \(chart.mingZhu)")
                Text("身界: \(chart.shenZhu)") // slightly renamed to fit better
            }
            .font(.system(size: scale * 0.09, weight: .medium))
            .foregroundColor(ZiWeiColors.textDark)

            HStack(spacing: 16) {
                Text("流年: \(chart.flowYearGanZhi)")
                Text("虚岁: \(chart.nominalAge)")
            }
            .font(.system(size: scale * 0.09))
            .foregroundColor(ZiWeiColors.textDark)

            Text("阳历: \(chart.clockTime)")
                .font(.system(size: scale * 0.08))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    // MARK: - 辅助方法
    
    private func starColor(_ star: Star) -> Color {
        switch star.category {
        case .zhengYao: return ZiWeiColors.zhengYaoColor
        case .fuXing: return ZiWeiColors.fuXingColor
        case .shaXing: return ZiWeiColors.shaXingColor
        case .zaYao: return ZiWeiColors.zaYaoColor
        case .liuNian: return ZiWeiColors.daXianColor
        }
    }
    
    private func huaShort(_ hua: String) -> String {
        switch hua {
        case "化禄": return "禄"
        case "化权": return "权"
        case "化科": return "科"
        case "化忌": return "忌"
        default: return ""
        }
    }
    
    private func huaColor(_ hua: String) -> Color {
        switch hua {
        case "化禄": return ZiWeiColors.huaLuColor
        case "化权": return ZiWeiColors.huaQuanColor
        case "化科": return ZiWeiColors.huaKeColor
        case "化忌": return ZiWeiColors.huaJiColor
        default: return .primary
        }
    }

    private func palaceMarkers(for palace: Palace) -> [String] {
        var markers: [String] = []
        if palace.position == chart.laiYinGong {
            markers.append("因")
        }
        if palace.position == chart.layer2Gong {
            markers.append("2")
        }
        if palace.position == chart.layer3Gong {
            markers.append("3")
        }
        return markers
    }

    // MARK: - 三方四正连线与几何计算
    
    @ViewBuilder
    private func drawSanFangSiZhengLines(for zhiIdx: Int, cellWidth: CGFloat, cellHeight: CGFloat, gap: CGFloat) -> some View {
        let p0 = getCoordinate(for: zhiIdx, cellWidth: cellWidth, cellHeight: cellHeight, gap: gap)
        let pDui = getCoordinate(for: (zhiIdx + 6) % 12, cellWidth: cellWidth, cellHeight: cellHeight, gap: gap)
        let pCai = getCoordinate(for: (zhiIdx + 4) % 12, cellWidth: cellWidth, cellHeight: cellHeight, gap: gap)
        let pGuan = getCoordinate(for: (zhiIdx + 8) % 12, cellWidth: cellWidth, cellHeight: cellHeight, gap: gap)

        Path { path in
            path.move(to: p0)
            path.addLine(to: pDui)
            
            path.move(to: p0)
            path.addLine(to: pCai)
            
            path.move(to: p0)
            path.addLine(to: pGuan)
            
            path.move(to: pCai)
            path.addLine(to: pGuan)
        }
        .stroke(ZiWeiColors.connectingLine, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        .shadow(color: ZiWeiColors.selectionCyan.opacity(0.5), radius: 3)
    }

    private func getCoordinate(for zhiIdx: Int, cellWidth: CGFloat, cellHeight: CGFloat, gap: CGFloat) -> CGPoint {
        let col: CGFloat
        let row: CGFloat
        switch zhiIdx {
        case 5: col = 0; row = 0 // 巳
        case 6: col = 1; row = 0 // 午
        case 7: col = 2; row = 0 // 未
        case 8: col = 3; row = 0 // 申
        case 4: col = 0; row = 1 // 辰
        case 9: col = 3; row = 1 // 酉
        case 3: col = 0; row = 2 // 卯
        case 10: col = 3; row = 2 // 戌
        case 2: col = 0; row = 3 // 寅
        case 1: col = 1; row = 3 // 丑
        case 0: col = 2; row = 3 // 子
        case 11: col = 3; row = 3 // 亥
        default: col = 0; row = 0
        }
        let x = (col + 0.5) * cellWidth + col * gap
        let y = (row + 0.5) * cellHeight + row * gap
        return CGPoint(x: x, y: y)
    }
}
