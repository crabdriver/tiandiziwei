// InputView.swift - 输入页面
// 看盘啦 · iOS 紫微斗数排盘

import SwiftUI

/// 出生信息输入页面
struct InputView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var showChartView = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 顶部标题区域（参考 iztro 文档站：主标题 + 一句说明）
                Section {
                    VStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(ZiWeiColors.inputHeroGradient)
                                .shadow(color: Color(red: 0.15, green: 0.12, blue: 0.28).opacity(0.35), radius: 18, y: 10)
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.22),
                                            Color(red: 1, green: 0.82, blue: 0.45).opacity(0.35),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 38, weight: .medium))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white.opacity(0.95), Color(red: 1, green: 0.88, blue: 0.55))
                                    .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
                                Text("看盘啦")
                                    .font(.system(.title2, design: .serif))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, y: 1)
                                Text("输入生辰，获取专属命盘")
                                    .font(.subheadline)
                                    .tracking(0.3)
                                    .foregroundStyle(.white.opacity(0.82))
                            }
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12))
                    .listRowBackground(Color.clear)
                }
                
                // 基本信息
                Section {
                    HStack {
                        Label("姓名", systemImage: "person.fill")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("输入姓名（可选）", text: $viewModel.input.name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Label("性别", systemImage: "figure.stand")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("性别", selection: $viewModel.input.isMale) {
                            Text("男").tag(true)
                            Text("女").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                } header: {
                    sectionHeaderTitle("基本信息")
                }
                
                // 出生时间
                Section {
                    Picker("时间模式", selection: $viewModel.input.timeInputMode) {
                        ForEach(TimeInputMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    if viewModel.input.timeInputMode == .lunarTime,
                       viewModel.hasLeapMonthForCurrentSelection() {
                        Toggle(isOn: $viewModel.input.isLeapMonth) {
                            Label("闰月", systemImage: "moonphase.waxing.crescent")
                        }
                    }
                    
                    Toggle(isOn: $viewModel.input.useMonthAdjustment) {
                        Label("换月", systemImage: "arrow.left.arrow.right")
                    }
                    
                    // 日期选择 (紧凑菜单模式)
                    HStack {
                        Label("日期", systemImage: "calendar")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $viewModel.input.year) {
                            ForEach(1900..<2100, id: \.self) { year in
                                Text("\(year)年").tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("", selection: $viewModel.input.month) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)月").tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("", selection: $viewModel.input.day) {
                            ForEach(viewModel.availableDays(), id: \.self) { day in
                                Text("\(day)日").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // 时间选择
                    HStack {
                        Label("时间", systemImage: "clock")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $viewModel.input.hour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d时", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("", selection: $viewModel.input.minute) {
                            ForEach(0..<60, id: \.self) { min in
                                Text(String(format: "%02d分", min)).tag(min)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // 时辰显示
                    HStack {
                        Label("时辰", systemImage: "sun.max")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.shiChenText(for: viewModel.input.hour))
                            .foregroundColor(ZiWeiColors.primary)
                            .fontWeight(.medium)
                    }
                    
                    Button(action: { viewModel.setCurrentTime() }) {
                        HStack {
                            Spacer()
                            Text("使用当前时间")
                            Spacer()
                        }
                    }
                    .foregroundColor(ZiWeiColors.primary)
                } header: {
                    sectionHeaderTitle("出生时间")
                }
                
                // 高级设置
                Section {
                    if viewModel.usesLongitudeCorrection() {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("经度", systemImage: "location.fill")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f°E", viewModel.input.longitude))
                                    .monospacedDigit()
                                    .foregroundColor(ZiWeiColors.primary)
                            }
                            Slider(
                                value: $viewModel.input.longitude,
                                in: 73...135,
                                step: 0.1
                            )
                            .tint(ZiWeiColors.primary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Label("事项", systemImage: "note.text")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("事项备注（可选）", text: $viewModel.input.eventNote)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    sectionHeaderTitle("高级设置")
                }
                
                // 排盘按钮
                Section {
                    Button(action: {
                        viewModel.generateChart()
                        showChartView = true
                    }) {
                        HStack(spacing: 8) {
                            Spacer(minLength: 0)
                            Image(systemName: "wand.and.stars")
                                .font(.body.weight(.semibold))
                            Text("开始排盘")
                                .font(.headline)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                    }
                    .accessibilityLabel("开始排盘")
                    .accessibilityHint("根据当前生辰生成紫微命盘")
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.primaryGradient)
                            .shadow(color: ZiWeiColors.primary.opacity(0.35), radius: 8, y: 4)
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .ziWeiInputBackdrop()
            .tint(ZiWeiColors.primary)
            .navigationTitle("输入信息")
            .navigationBarTitleDisplayMode(.inline)
            .ziWeiNavigationChrome()
            .onAppear {
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.timeInputMode) { _, _ in
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.year) { _, _ in
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.month) { _, _ in
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.isLeapMonth) { _, _ in
                viewModel.normalizeInput()
            }
            .navigationDestination(isPresented: $showChartView) {
                ChartDisplayView(viewModel: viewModel)
            }
        }
    }
    
    /// 分组标题（类似文档站的小节样式）
    private func sectionHeaderTitle(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(ZiWeiColors.textMuted)
            .textCase(nil)
    }
}
