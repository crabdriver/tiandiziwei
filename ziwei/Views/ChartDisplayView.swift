// ChartDisplayView.swift - 排盘结果显示页
// 紫微星语 iOS 版

import SwiftUI

/// 排盘结果展示页面
struct ChartDisplayView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签切换
            Picker("图表类型", selection: $selectedTab) {
                Text("紫微盘").tag(0)
                Text("八字盘").tag(1)
                Text("详情").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // 内容
            TabView(selection: $selectedTab) {
                // 紫微盘面
                if let chart = viewModel.ziWeiChart {
                    ScrollView {
                        ZiWeiChartView(chart: chart)
                            .padding(8)
                    }
                    .tag(0)
                }
                
                // 八字盘面
                if let baZi = viewModel.baZiChart {
                    ScrollView {
                        BaZiChartView(chart: baZi)
                            .padding()
                    }
                    .tag(1)
                }
                
                // 详情
                if let chart = viewModel.ziWeiChart {
                    ScrollView {
                        detailView(chart: chart)
                            .padding()
                    }
                    .tag(2)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(viewModel.input.name.isEmpty ? "排盘结果" : viewModel.input.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 详情视图
    
    @ViewBuilder
    private func detailView(chart: ZiWeiChart) -> some View {
        VStack(spacing: 16) {
            // 基本信息卡片
            GroupBox("基本信息") {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow("命宫", chart.mingGong)
                    infoRow("身宫", chart.shenGong)
                    infoRow("五行局", chart.wuXingJu)
                    infoRow("命主", chart.mingZhu)
                    infoRow("身主", chart.shenZhu)
                    infoRow("来因宫", chart.laiYinGong)
                    infoRow("流斗", chart.liuDou)
                    infoRow("当前流年", chart.flowYearGanZhi)
                    infoRow("当前虚岁", "\(chart.nominalAge)")
                    infoRow("时间模式", chart.timeInputMode.title)
                    infoRow(
                        "阴历日期",
                        "\(chart.lunarDate.year)年\(chart.lunarDate.isLeapMonth ? "闰" : "")\(chart.lunarDate.month)月\(chart.lunarDate.day)日"
                    )
                    infoRow("农历月计数", "\(chart.lunarMonthCount)")
                    infoRow("钟表时间", chart.clockTime)
                    infoRow("真太阳时", chart.trueSolarTime)
                    infoRow("换月", chart.useMonthAdjustment ? "已启用" : "未启用")
                }
            }

            GroupBox("APK 对照") {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow("F 值", viewModel.input.timeInputMode.apkCode)
                    infoRow("性别码", viewModel.input.apkGenderCode)
                    infoRow("经度", viewModel.input.apkLongitudeString)
                    infoRow("Payload", viewModel.input.apkPayloadString)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("完整参数串")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.input.apkFullString())
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            
            // 四化信息
            GroupBox("四化飞星") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(chart.siHuaInfo.keys.sorted()), id: \.self) { star in
                        if let hua = chart.siHuaInfo[star] {
                            HStack {
                                Text(star)
                                    .foregroundColor(ZiWeiColors.zhengYaoColor)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(hua)
                                    .foregroundColor(huaColor(hua))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            
            // 十二宫详情
            GroupBox("十二宫详情") {
                ForEach(chart.palaces, id: \.name) { palace in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(palace.name)
                                .font(.headline)
                                .foregroundColor(ZiWeiColors.gongNameColor)
                            
                            Text("(\(palace.tianGan)\(palace.position))")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if !palace.daXian.isEmpty {
                                Text("大限: \(palace.daXian)")
                                    .font(.caption)
                                    .foregroundColor(ZiWeiColors.daXianColor)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            infoRow("长生", palace.changSheng)
                            infoRow("岁前", palace.suiQian)
                            infoRow("将前", palace.jiangQian)
                            infoRow("博士", palace.boshi)
                            infoRow("小限", palace.xiaoXian.isEmpty ? "-" : palace.xiaoXian)
                        }
                        .font(.caption)

                        if !palace.gongTransforms.isEmpty {
                            transformSection(title: "宫干四化", transforms: palace.gongTransforms)
                        }

                        if !palace.chongHua.isEmpty {
                            transformSection(title: "冲化", transforms: palace.chongHua)
                        }

                        if !palace.ziHua.isEmpty {
                            transformSection(title: "自化", transforms: palace.ziHua)
                        }

                        // 星曜
                        FlowLayout(spacing: 6) {
                            ForEach(palace.stars, id: \.name) { star in
                                HStack(spacing: 2) {
                                    Text(star.name)
                                        .font(.caption)
                                        .foregroundColor(starColor(star))
                                    if let hua = star.siHua {
                                        Text(huaShortText(hua))
                                            .font(.caption2)
                                            .foregroundColor(huaColor(hua))
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func transformSection(title: String, transforms: [PalaceTransform]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(transforms.enumerated()), id: \.offset) { _, transform in
                HStack {
                    Text("\(transform.star)\(huaShortText(transform.hua))")
                        .foregroundColor(huaColor(transform.hua))
                    Spacer()
                    Text("\(transform.targetPalace)-\(transform.targetPosition)")
                        .foregroundColor(.secondary)
                    Text("\(transform.strength)%")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
    }
    
    private func starColor(_ star: Star) -> Color {
        switch star.category {
        case .zhengYao: return ZiWeiColors.zhengYaoColor
        case .fuXing: return ZiWeiColors.fuXingColor
        case .shaXing: return ZiWeiColors.shaXingColor
        case .zaYao: return ZiWeiColors.zaYaoColor
        case .liuNian: return ZiWeiColors.daXianColor
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
    
    private func huaShortText(_ hua: String) -> String {
        switch hua {
        case "化禄": return "禄"
        case "化权": return "权"
        case "化科": return "科"
        case "化忌": return "忌"
        default: return ""
        }
    }
}

/// 八字盘面视图
struct BaZiChartView: View {
    let chart: BaZiChart
    
    var body: some View {
        VStack(spacing: 16) {
            // 四柱显示
            HStack(spacing: 16) {
                pillarView(title: "年柱", pillar: chart.yearPillar)
                pillarView(title: "月柱", pillar: chart.monthPillar)
                pillarView(title: "日柱", pillar: chart.dayPillar, isDayMaster: true)
                pillarView(title: "时柱", pillar: chart.hourPillar)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // 五行力量
            GroupBox("五行力量") {
                HStack(spacing: 12) {
                    ForEach(["木", "火", "土", "金", "水"], id: \.self) { element in
                        VStack {
                            Text(element)
                                .font(.headline)
                                .foregroundColor(elementColor(element))
                            
                            let strength = chart.wuXingStrength[element] ?? 0
                            Text("\(strength)")
                                .font(.caption)
                                .monospacedDigit()
                            
                            Rectangle()
                                .fill(elementColor(element))
                                .frame(width: 30, height: CGFloat(strength) / 3)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // 纳音
            GroupBox("纳音五行") {
                VStack(alignment: .leading, spacing: 4) {
                    naYinRow("年柱", chart.yearPillar)
                    naYinRow("月柱", chart.monthPillar)
                    naYinRow("日柱", chart.dayPillar)
                    naYinRow("时柱", chart.hourPillar)
                }
            }
            
            // 神煞
            if !chart.shenSha.isEmpty {
                GroupBox("神煞") {
                    FlowLayout(spacing: 6) {
                        ForEach(chart.shenSha, id: \.self) { sha in
                            Text(sha)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func pillarView(title: String, pillar: BaZiPillar, isDayMaster: Bool = false) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 十神
            Text(isDayMaster ? "日主" : BaZiEngine.shiShenShort(pillar.shiShen))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 天干
            Text(pillar.tianGan)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BaZiColors.colorFor(pillar.tianGan))
            
            // 地支
            Text(pillar.diZhi)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BaZiColors.colorFor(pillar.diZhi))
            
            // 藏干
            VStack(spacing: 2) {
                ForEach(pillar.hiddenGan, id: \.self) { gan in
                    HStack(spacing: 2) {
                        Text(gan)
                            .font(.caption)
                            .foregroundColor(BaZiColors.colorFor(gan))
                        Text(BaZiEngine.shiShenShort(
                            BaZiEngine.getShiShen(dayGan: chart.dayMaster, otherGan: gan)
                        ))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 长生
            Text(pillar.changSheng)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isDayMaster ? ZiWeiColors.mingGongHighlight : Color.clear)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func naYinRow(_ title: String, _ pillar: BaZiPillar) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(pillar.ganZhi)
                .fontWeight(.bold)
            Text("- \(pillar.naYin)")
                .foregroundColor(ZiWeiColors.primary)
        }
        .font(.subheadline)
    }
    
    private func elementColor(_ element: String) -> Color {
        switch element {
        case "木": return BaZiColors.wood
        case "火": return BaZiColors.fire
        case "土": return BaZiColors.earth
        case "金": return BaZiColors.metal
        case "水": return BaZiColors.water
        default: return .primary
        }
    }
}

/// FlowLayout - 流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
