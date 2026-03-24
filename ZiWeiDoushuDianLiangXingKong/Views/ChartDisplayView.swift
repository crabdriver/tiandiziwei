// ChartDisplayView.swift - 排盘结果显示页
// 紫微斗数-点亮星空版 iOS 版

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
                Text("排盘详情").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
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
                
                // 详情
                if let chart = viewModel.ziWeiChart {
                    detailView(chart: chart)
                        .tag(1)
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
        List {
            // 基本信息卡片
            Section(header: Text("基本信息")) {
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

            Section(header: Text("APK 对照")) {
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
                .padding(.vertical, 4)
            }
            
            // 四化信息
            Section(header: Text("四化飞星")) {
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
            
            // 十二宫详情
            Section(header: Text("十二宫详情")) {
                ForEach(chart.palaces, id: \.name) { palace in
                    VStack(alignment: .leading, spacing: 8) {
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
                        
                        HStack {
                            Text("长生: \(palace.changSheng)")
                            Spacer()
                            Text("岁前: \(palace.suiQian)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Text("将前: \(palace.jiangQian)")
                            Spacer()
                            Text("博士: \(palace.boshi)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if !palace.xiaoXian.isEmpty {
                            Text("小限: \(palace.xiaoXian)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

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
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
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
