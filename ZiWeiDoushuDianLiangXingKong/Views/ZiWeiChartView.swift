// ZiWeiChartView.swift - 紫微盘面视图
// 看盘啦 · iOS 紫微斗数排盘（SwiftUI Canvas）

import SwiftUI

/// 紫微排盘盘面视图
struct ZiWeiChartView: View {
    let chart: ZiWeiChart

    /// 用于 `.sheet(item:)` 的轻量标识
    private struct PresentedPalace: Identifiable {
        let id: Int
    }

    @State private var presentedPalaceSheet: PresentedPalace?

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let cellSize = (size - 1.5) / 4 // 减去间距的宽度
            
            ZStack {
                // 盘面底色（宣纸感，与 iztro 类排盘展示常见的「纸面」一致）
                ZiWeiColors.chartPaper
                
                // 十二宫格 (通过 spacing 产生 0.5px 的网格线)
                VStack(spacing: 0.5) {
                    // 第一行: 巳 午 未 申 (索引: 5,6,7,8)
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(5), cellSize: cellSize)
                        palaceCell(atIndex: positionToIndex(6), cellSize: cellSize)
                        palaceCell(atIndex: positionToIndex(7), cellSize: cellSize)
                        palaceCell(atIndex: positionToIndex(8), cellSize: cellSize)
                    }
                    
                    // 第二行: 辰 [中央] [中央] 酉
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(4), cellSize: cellSize)
                        
                        // 中央区域上半
                        centerView(cellSize: cellSize)
                            .frame(width: cellSize * 2 + 0.5, height: cellSize)
                            .background(ZiWeiColors.chartPaper)
                        
                        palaceCell(atIndex: positionToIndex(9), cellSize: cellSize)
                    }
                    
                    // 第三行: 卯 [中央] [中央] 戌
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(3), cellSize: cellSize)
                        
                        // 中央区域下半
                        centerViewBottom(cellSize: cellSize)
                            .frame(width: cellSize * 2 + 0.5, height: cellSize)
                            .background(ZiWeiColors.chartPaper)
                        
                        palaceCell(atIndex: positionToIndex(10), cellSize: cellSize)
                    }
                    
                    // 第四行: 寅 丑 子 亥 (索引: 2,1,0,11)
                    HStack(spacing: 0.5) {
                        palaceCell(atIndex: positionToIndex(2), cellSize: cellSize)
                        palaceCell(atIndex: positionToIndex(1), cellSize: cellSize)
                        palaceCell(atIndex: positionToIndex(0), cellSize: cellSize)
                        palaceCell(atIndex: positionToIndex(11), cellSize: cellSize)
                    }
                }
                .background(ZiWeiColors.border) // 网格线颜色
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(ZiWeiColors.chartFrame.opacity(0.9), lineWidth: 1)
                )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .sheet(item: $presentedPalaceSheet) { item in
            NavigationStack {
                ScrollView {
                    if item.id < chart.palaces.count {
                        PalaceDetailContent(palace: chart.palaces[item.id])
                            .padding(16)
                    }
                }
                .background(ZiWeiColors.screenBackdropGradient)
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
    private func palaceCell(atIndex index: Int?, cellSize: CGFloat) -> some View {
        if let idx = index, idx < chart.palaces.count {
            let palace = chart.palaces[idx]
            let isMingGong = palace.name == "命宫"
            let markers = palaceMarkers(for: palace)
            
            ZStack {
                // 宫格背景
                Rectangle()
                    .fill(isMingGong ? ZiWeiColors.mingGongHighlight : ZiWeiColors.chartPaper)

                if !markers.isEmpty {
                    VStack(alignment: .trailing, spacing: 1) {
                        ForEach(markers, id: \.self) { marker in
                            Text(marker)
                                .font(.system(size: cellSize * 0.08, weight: .bold))
                                .foregroundColor(marker == "因" ? ZiWeiColors.huaJiColor : ZiWeiColors.huaQuanColor)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 3)
                    .padding(.trailing, 4)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    // 星曜列表
                    starsView(palace: palace, cellSize: cellSize)
                    
                    Spacer(minLength: 0)
                    
                    // 底部信息
                    HStack(alignment: .bottom) {
                        // 左下角：岁前/将前/博士
                        VStack(alignment: .leading, spacing: 0) {
                            if !palace.suiQian.isEmpty {
                                Text(palace.suiQian)
                                    .font(.system(size: cellSize * 0.055))
                                    .foregroundColor(ZiWeiColors.zaYaoColor)
                            }
                            if !palace.jiangQian.isEmpty {
                                Text(palace.jiangQian)
                                    .font(.system(size: cellSize * 0.055))
                                    .foregroundColor(ZiWeiColors.zaYaoColor)
                            }
                            if !palace.boshi.isEmpty {
                                Text(palace.boshi)
                                    .font(.system(size: cellSize * 0.06))
                                    .foregroundColor(ZiWeiColors.zaYaoColor)
                            }
                        }
                        
                        Spacer(minLength: 0)
                        
                        // 右下角：宫名、地支、大限
                        VStack(alignment: .trailing, spacing: 0) {
                            // 大限
                            if !palace.daXian.isEmpty {
                                Text(palace.daXian)
                                    .font(.system(size: cellSize * 0.065))
                                    .foregroundColor(ZiWeiColors.daXianColor)
                            }

                            if !palace.xiaoXian.isEmpty {
                                Text(palace.xiaoXian)
                                    .font(.system(size: cellSize * 0.06))
                                    .foregroundColor(ZiWeiColors.huaQuanColor)
                            }
                            
                            // 宫干 + 地支
                            HStack(spacing: 1) {
                                Text(palace.tianGan)
                                    .font(.system(size: cellSize * 0.09, weight: .bold))
                                    .foregroundColor(ZiWeiColors.textDark)
                                Text(palace.position)
                                    .font(.system(size: cellSize * 0.09, weight: .bold))
                                    .foregroundColor(ZiWeiColors.textDark)
                            }
                            
                            // 宫名
                            Text(palace.name)
                                .font(.system(size: cellSize * 0.08, weight: .bold))
                                .foregroundColor(ZiWeiColors.gongNameColor)
                                .padding(.top, 1)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
                }
                .padding(2)
            }
            .frame(width: cellSize, height: cellSize)
            .accessibilityLabel("\(palace.name)，\(palace.tianGan)\(palace.position)")
            .accessibilityHint("打开该宫星曜与四化详情")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                presentedPalaceSheet = PresentedPalace(id: idx)
            }
        } else {
            Rectangle()
                .fill(ZiWeiColors.chartPaper)
                .frame(width: cellSize, height: cellSize)
        }
    }
    
    /// 星曜列表视图 (优化排版：主星略大，辅星稍小)
    @ViewBuilder
    private func starsView(palace: Palace, cellSize: CGFloat) -> some View {
        let zhengYaoSize = cellSize * 0.085
        let otherSize = cellSize * 0.07
        
        let zhengYao = palace.stars.filter { $0.category == .zhengYao }
        let others = palace.stars.filter { $0.category != .zhengYao }
        
        HStack(alignment: .top, spacing: 4) {
            // 左列：主星
            if !zhengYao.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(zhengYao, id: \.name) { star in
                        starRow(star: star, fontSize: zhengYaoSize, isZhengYao: true)
                    }
                }
            }
            
            // 右列：辅星/煞星/杂曜 (最多显示5个防止溢出)
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(others.prefix(5), id: \.name) { star in
                        starRow(star: star, fontSize: otherSize, isZhengYao: false)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func starRow(star: Star, fontSize: CGFloat, isZhengYao: Bool) -> some View {
        HStack(spacing: 1) {
            Text(star.name)
                .font(.system(size: fontSize, weight: isZhengYao ? .bold : .medium))
                .foregroundColor(starColor(star))
            
            if let brightness = star.brightness {
                Text(brightness)
                    .font(.system(size: fontSize * 0.8))
                    .foregroundColor(.gray)
            }
            
            if let hua = star.siHua {
                Text(huaShort(hua))
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundColor(huaColor(hua))
                    .padding(.leading, 1)
            }
        }
    }
    
    /// 中央区域上半部分
    @ViewBuilder
    private func centerView(cellSize: CGFloat) -> some View {
        VStack(spacing: 6) {
            // 标题
            Text("看盘啦")
                .font(.system(size: cellSize * 0.14, weight: .bold, design: .serif))
                .foregroundColor(ZiWeiColors.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
            
            // 信息行 (四柱)
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("年柱").font(.system(size: cellSize * 0.05)).foregroundColor(.secondary)
                    Text(chart.lunarDate.yearGan + chart.lunarDate.yearZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
                VStack(spacing: 2) {
                    Text("月柱").font(.system(size: cellSize * 0.05)).foregroundColor(.secondary)
                    Text(chart.lunarDate.monthGan + chart.lunarDate.monthZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
                VStack(spacing: 2) {
                    Text("日柱").font(.system(size: cellSize * 0.05)).foregroundColor(.secondary)
                    Text(chart.lunarDate.dayGan + chart.lunarDate.dayZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
                VStack(spacing: 2) {
                    Text("时柱").font(.system(size: cellSize * 0.05)).foregroundColor(.secondary)
                    Text(chart.lunarDate.hourGan + chart.lunarDate.hourZhi)
                        .foregroundColor(ZiWeiColors.textDark)
                }
            }
            .font(.system(size: cellSize * 0.1, weight: .bold))
        }
    }
    
    /// 中央区域下半部分
    @ViewBuilder
    private func centerViewBottom(cellSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Text("命主: \(chart.mingZhu)")
                Text("身主: \(chart.shenZhu)")
                Text("身宫: \(chart.shenGong)")
            }
            .font(.system(size: cellSize * 0.08, weight: .medium))
            .foregroundColor(ZiWeiColors.textDark)
            
            Text(chart.wuXingJu)
                .font(.system(size: cellSize * 0.085, weight: .bold))
                .foregroundColor(ZiWeiColors.primary)
                .padding(.vertical, 2)

            HStack(spacing: 12) {
                Text("流年: \(chart.flowYearGanZhi)")
                Text("虚岁: \(chart.nominalAge)")
            }
            .font(.system(size: cellSize * 0.075))
            .foregroundColor(ZiWeiColors.textDark)

            HStack(spacing: 12) {
                Text("来因: \(chart.laiYinGong)")
                Text("流斗: \(chart.liuDou)")
            }
            .font(.system(size: cellSize * 0.075))
            .foregroundColor(ZiWeiColors.textDark)
            
            VStack(spacing: 2) {
                Text("钟表: \(chart.clockTime)")
                Text(chart.timeInputMode == .trueSolarTime ? "真太阳输入: \(chart.trueSolarTime)" : "真太阳: \(chart.trueSolarTime)")
            }
            .font(.system(size: cellSize * 0.065))
            .foregroundColor(.secondary)
            .padding(.top, 2)
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
}
