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
            // 标签切换（胶囊分段，比系统默认条更贴近现代排盘站点的切换）
            HStack(spacing: 0) {
                tabChip(title: "紫微盘", systemImage: "circle.grid.3x3", index: 0)
                tabChip(title: "排盘详情", systemImage: "list.bullet.rectangle", index: 1)
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ZiWeiColors.border.opacity(0.5),
                                ZiWeiColors.gold.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .accessibilityLabel("排盘视图切换")
            .accessibilityHint("在紫微命盘与文字详情之间切换")
            
            // 内容
            TabView(selection: $selectedTab) {
                // 紫微盘面
                if let chart = viewModel.ziWeiChart {
                    ScrollView {
                        ZiWeiChartView(chart: chart)
                            .padding(10)
                            .shadow(color: Color.black.opacity(0.07), radius: 16, y: 8)
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
        .background(ZiWeiColors.screenBackdropGradient.ignoresSafeArea())
        .navigationTitle(viewModel.input.name.isEmpty ? "排盘结果" : viewModel.input.name)
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
        .background(ZiWeiColors.screenBackdropGradient)
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
