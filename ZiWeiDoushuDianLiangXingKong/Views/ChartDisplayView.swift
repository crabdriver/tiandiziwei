// ChartDisplayView.swift - 排盘结果显示页
// 看盘啦 · iOS 紫微斗数排盘

import SwiftUI

/// 排盘结果展示页面
struct ChartDisplayView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var selectedTab = 0
    @State private var showApkDebug = false
    
    var body: some View {
        VStack(spacing: 0) {
            // ── 标签切换栏 ──
            HStack(spacing: 0) {
                tabChip(title: "命盘", systemImage: "circle.grid.3x3", index: 0)
                tabChip(title: "详情", systemImage: "list.bullet.rectangle", index: 1)
            }
            .padding(4)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(ZiWeiColors.border.opacity(0.4)),
                alignment: .bottom
            )
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 4)

            // ── 内容区域 ──
            if selectedTab == 0 {
                // 命盘：全屏满铺，无 ScrollView
                if let chart = viewModel.ziWeiChart {
                    ZiWeiChartView(chart: chart)
                        .padding(6)
                }
                Divider().background(ZiWeiColors.border.opacity(0.25))
                timeTravelBar
            } else {
                if let chart = viewModel.ziWeiChart {
                    detailView(chart: chart)
                }
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle(viewModel.input.name.isEmpty ? "命盘" : viewModel.input.name)
        .navigationBarTitleDisplayMode(.inline)
        .ziWeiNavigationChrome()
    }
    
    private func detailSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(ZiWeiColors.textMuted)
            .textCase(nil)
    }
    
    private func tabChip(title: String, systemImage: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                Group {
                    if selectedTab == index {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ZiWeiColors.cardSurface,
                                        ZiWeiColors.cardSurface.opacity(0.92)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: ZiWeiColors.primary.opacity(0.12), radius: 6, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(ZiWeiColors.border.opacity(0.45), lineWidth: 0.5)
                            )
                    }
                }
            )
            .foregroundStyle(selectedTab == index ? ZiWeiColors.textDark : ZiWeiColors.textMuted)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 时间穿越工具栏（流年大限切换）
    
    private var timeTravelBar: some View {
        HStack {
            Button(action: { viewModel.adjustTargetYear(by: -1) }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(ZiWeiColors.primary, ZiWeiColors.border.opacity(0.5))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(viewModel.targetYear == nil ? "静态本命盘" : "动态流年盘")
                    .font(.caption2)
                    .foregroundStyle(ZiWeiColors.textMuted)
                
                if let year = viewModel.targetYear {
                    Text("\(year) 年")
                        .font(.headline.weight(.heavy))
                        .foregroundColor(ZiWeiColors.huaQuanColor)
                } else {
                    Text("当前时空")
                        .font(.headline.weight(.heavy))
                        .foregroundColor(ZiWeiColors.primary)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    if viewModel.targetYear == nil {
                        viewModel.adjustTargetYear(by: 0) // 初始化流年
                    } else {
                        viewModel.resetToCurrentYear() // 返回本命
                    }
                }
            }) {
                Text(viewModel.targetYear == nil ? "看流年" : "复原")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ZiWeiColors.primary.opacity(0.15))
                    .foregroundColor(ZiWeiColors.primary)
                    .cornerRadius(12)
            }
            
            Spacer()
            
            Button(action: { viewModel.adjustTargetYear(by: 1) }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(ZiWeiColors.primary, ZiWeiColors.border.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - 详情视图
    
    @ViewBuilder
    private func detailView(chart: ZiWeiChart) -> some View {
        List {
            // 基本信息卡片
            Section(header: detailSectionHeader("基本信息")) {
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

            Section {
                DisclosureGroup(isExpanded: $showApkDebug) {
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
                } label: {
                    Text("APK 对照（开发者）")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(ZiWeiColors.textMuted)
                }
            }
            
            // 四化信息
            Section(header: detailSectionHeader("四化飞星")) {
                ForEach(Array(chart.siHuaInfo.keys.sorted()), id: \.self) { star in
                    if let hua = chart.siHuaInfo[star] {
                        HStack {
                            Text(star)
                                .foregroundColor(ZiWeiColors.zhengYaoColor)
                                .fontWeight(.bold)
                            Spacer()
                            Text(hua)
                                .foregroundColor(ChartPalette.huaColor(hua))
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            
            // 十二宫详情
            Section(header: detailSectionHeader("十二宫详情")) {
                ForEach(chart.palaces, id: \.name) { palace in
                    PalaceDetailContent(palace: palace)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .ziWeiInputBackdrop()
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
