// InputView.swift - 输入页面
// 紫微斗数排盘 · 重构版（Apple Design Language + 文墨天机极简美学）

import SwiftUI

struct InputView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var showChartView = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 全局自适应背景
                Color(UIColor.systemBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ── HERO SECTION ──────────────────────────────────────
                        heroSection

                        // ── INPUT CARDS ───────────────────────────────────────
                        VStack(spacing: 12) {
                            basicInfoCard
                            birthTimeCard
                            if viewModel.usesLongitudeCorrection() {
                                longitudeCard
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                        // ── CTA BUTTON ────────────────────────────────────────
                        startButton
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showChartView) {
                ChartDisplayView(viewModel: viewModel)
            }
            .onAppear { viewModel.normalizeInput() }
            .onChange(of: viewModel.input.timeInputMode) { _, _ in viewModel.normalizeInput() }
            .onChange(of: viewModel.input.year) { _, _ in viewModel.normalizeInput() }
            .onChange(of: viewModel.input.month) { _, _ in viewModel.normalizeInput() }
            .onChange(of: viewModel.input.isLeapMonth) { _, _ in viewModel.normalizeInput() }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 0) {
            // 顶部状态栏安全区 + 标题
            VStack(spacing: 16) {
                // 标志图标
                ZStack {
                    Circle()
                        .fill(Color(white: 0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(white: 0.95), Color(hue: 0.12, saturation: 0.6, brightness: 0.95)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                // 主标题 — Apple Display 风格：大、紧、白
                Text("点亮星空")
                    .font(.system(size: 42, weight: .semibold, design: .default))
                    .tracking(-0.5)
                    .foregroundColor(.primary)

                // 副标题 — 功能说明，浅灰降调
                Text("输入生辰，推演命盘")
                    .font(.system(size: 16, weight: .regular))
                    .tracking(-0.2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
    }

    // MARK: - Basic Info Card

    private var basicInfoCard: some View {
        VStack(spacing: 0) {
            cardLabel("个人信息")

            VStack(spacing: 0) {
                // 姓名行
                rowField(icon: "person", label: "姓名") {
                    TextField("可选", text: $viewModel.input.name)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                }

                rowDivider()

                // 性别行
                rowField(icon: "person.2", label: "性别") {
                    HStack(spacing: 8) {
                        genderPill(label: "男", isSelected: viewModel.input.isMale) {
                            viewModel.input.isMale = true
                        }
                        genderPill(label: "女", isSelected: !viewModel.input.isMale) {
                            viewModel.input.isMale = false
                        }
                    }
                }

                rowDivider()

                // 时间模式行
                rowField(icon: "clock.badge", label: "时间模式") {
                    Menu {
                        ForEach(TimeInputMode.allCases, id: \.self) { mode in
                            Button(mode.title) {
                                viewModel.input.timeInputMode = mode
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.input.timeInputMode.title)
                                .foregroundColor(Color(white: 0.65))
                                .font(.system(size: 15))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(white: 0.45))
                        }
                    }
                }
            }
            .card()
        }
    }

    // MARK: - Birth Time Card

    private var birthTimeCard: some View {
        VStack(spacing: 0) {
            cardLabel("出生时间")

            VStack(spacing: 0) {
                // 日期行
                rowField(icon: "calendar", label: "日期") {
                    HStack(spacing: 0) {
                        compactPicker(selection: $viewModel.input.year, items: Array(1995..<2100)) { "\($0)年" }
                        compactPicker(selection: $viewModel.input.month, items: Array(1...12)) { "\($0)月" }
                        compactPicker(selection: $viewModel.input.day, items: viewModel.availableDays()) { "\($0)日" }
                    }
                }

                rowDivider()

                // 时间行
                rowField(icon: "clock", label: "时间") {
                    HStack(spacing: 0) {
                        compactPicker(selection: $viewModel.input.hour, items: Array(0..<24)) { String(format: "%02d时", $0) }
                        compactPicker(selection: $viewModel.input.minute, items: Array(0..<60)) { String(format: "%02d分", $0) }
                    }
                }

                rowDivider()

                // 时辰提示
                HStack {
                    Image(systemName: "sun.horizon")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.4))
                    Text("时辰")
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.45))
                    Spacer()
                    Text(viewModel.shiChenText(for: viewModel.input.hour))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ZiWeiColors.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                // 闰月 Toggle（仅阴历且有闰月时显示）
                if viewModel.input.timeInputMode == .lunarTime,
                   viewModel.hasLeapMonthForCurrentSelection() {
                    rowDivider()
                    rowField(icon: "moonphase.waxing.crescent", label: "闰月") {
                        Toggle("", isOn: $viewModel.input.isLeapMonth)
                            .tint(ZiWeiColors.primary)
                            .labelsHidden()
                    }
                }

                rowDivider()

                // 换月 Toggle
                rowField(icon: "arrow.left.arrow.right", label: "节气换月") {
                    Toggle("", isOn: $viewModel.input.useMonthAdjustment)
                        .tint(ZiWeiColors.primary)
                        .labelsHidden()
                }

                rowDivider()

                // 使用当前时间
                Button(action: { viewModel.setCurrentTime() }) {
                    HStack {
                        Image(systemName: "location.circle")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.4))
                        Text("使用当前时间")
                            .font(.system(size: 15))
                            .foregroundColor(ZiWeiColors.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.35))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.plain)
            }
            .card()
        }
    }

    // MARK: - Longitude Card

    private var longitudeCard: some View {
        VStack(spacing: 0) {
            cardLabel("真太阳时修正")

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.4))
                    Text("经度")
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.45))
                    Spacer()
                    Text(String(format: "%.1f° %@", abs(viewModel.input.longitude), viewModel.input.longitude >= 0 ? "E" : "W"))
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundColor(ZiWeiColors.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                Slider(value: $viewModel.input.longitude, in: -180...180, step: 0.5)
                    .tint(ZiWeiColors.primary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .card()
        }
    }

    // MARK: - CTA Button

    private var startButton: some View {
        Button(action: {
            viewModel.generateChart()
            showChartView = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 17, weight: .semibold))
                Text("开始排盘")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                ZiWeiColors.primary
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: ZiWeiColors.primary.opacity(0.35), radius: 18, y: 6)
        .accessibilityLabel("开始排盘")
    }

    // MARK: - Helpers

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(Color(white: 0.4))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.bottom, 6)
    }

    private func rowDivider() -> some View {
        Divider()
            .background(Color(white: 0.18))
            .padding(.leading, 44)
    }

    @ViewBuilder
    private func rowField<Trailing: View>(icon: String, label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private func compactPicker<T: Hashable>(selection: Binding<T>, items: [T], label: @escaping (T) -> String) -> some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button(label(item)) { selection.wrappedValue = item }
            }
        } label: {
            Text(label(selection.wrappedValue))
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.75))
                .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func genderPill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    isSelected ? ZiWeiColors.primary : Color(UIColor.tertiarySystemFill)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Card Modifier

private extension View {
    func card() -> some View {
        self
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
