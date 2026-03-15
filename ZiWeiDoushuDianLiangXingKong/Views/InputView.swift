// InputView.swift - 输入页面
// 紫微斗数-点亮星空版 iOS 版

import SwiftUI

/// 出生信息输入页面
struct InputView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var showChartView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                let availableDays = viewModel.availableDays()

                VStack(spacing: 20) {
                    // 顶部标题
                    headerView
                    
                    // 姓名输入
                    inputCard(title: "基本信息") {
                        VStack(spacing: 12) {
                            HStack {
                                Label("姓名", systemImage: "person.fill")
                                    .foregroundColor(.secondary)
                                TextField("输入姓名（可选）", text: $viewModel.input.name)
                                    .textFieldStyle(.roundedBorder)
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
                        }
                    }
                    
                    // 日期时间
                    inputCard(title: "出生时间") {
                        VStack(spacing: 12) {
                            // 阴阳历切换
                            HStack {
                                Label("时间模式", systemImage: "calendar")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("时间模式", selection: $viewModel.input.timeInputMode) {
                                    ForEach(TimeInputMode.allCases, id: \.self) { mode in
                                        Text(mode.title).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 240)
                            }

                            if viewModel.input.timeInputMode == .lunarTime,
                               viewModel.hasLeapMonthForCurrentSelection() {
                                Toggle(isOn: $viewModel.input.isLeapMonth) {
                                    Label("闰月", systemImage: "moonphase.waxing.crescent")
                                        .foregroundColor(.secondary)
                                }
                            }

                            Toggle(isOn: $viewModel.input.useMonthAdjustment) {
                                Label("换月", systemImage: "arrow.left.arrow.right")
                                    .foregroundColor(.secondary)
                            }
                            
                            // 年月日
                            HStack(spacing: 8) {
                                VStack(alignment: .leading) {
                                    Text("年")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("年", selection: $viewModel.input.year) {
                                        ForEach(1900..<2100, id: \.self) { year in
                                            Text("\(year)").tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("月")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("月", selection: $viewModel.input.month) {
                                        ForEach(1...12, id: \.self) { month in
                                            Text("\(month)月").tag(month)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("日")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("日", selection: $viewModel.input.day) {
                                        ForEach(availableDays, id: \.self) { day in
                                            Text("\(day)日").tag(day)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                            }
                            
                            // 时辰
                            HStack(spacing: 8) {
                                VStack(alignment: .leading) {
                                    Text("时")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("时", selection: $viewModel.input.hour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d时", hour)).tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("分")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("分", selection: $viewModel.input.minute) {
                                        ForEach(0..<60, id: \.self) { min in
                                            Text(String(format: "%02d分", min)).tag(min)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                // 时辰显示
                                VStack {
                                    Text("时辰")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(viewModel.shiChenText(for: viewModel.input.hour))
                                        .font(.body)
                                        .foregroundColor(ZiWeiColors.primary)
                                        .frame(height: 100)
                                }
                            }
                            
                            // 快捷按钮：使用当前时间
                            Button(action: { viewModel.setCurrentTime() }) {
                                Label("使用当前时间", systemImage: "clock.fill")
                                    .font(.subheadline)
                                    .foregroundColor(ZiWeiColors.primary)
                            }
                        }
                    }
                    
                    // 高级设置
                    inputCard(title: "高级设置") {
                        VStack(spacing: 12) {
                            if viewModel.usesLongitudeCorrection() {
                                HStack {
                                    Label("经度", systemImage: "location.fill")
                                        .foregroundColor(.secondary)
                                    Slider(
                                        value: $viewModel.input.longitude,
                                        in: 73...135,
                                        step: 0.1
                                    )
                                    Text(String(format: "%.1f°E", viewModel.input.longitude))
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                            }
                            
                            HStack {
                                Label("事项", systemImage: "note.text")
                                    .foregroundColor(.secondary)
                                TextField("事项备注（可选）", text: $viewModel.input.eventNote)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    
                    // 排盘按钮
                    Button(action: {
                        viewModel.generateChart()
                        showChartView = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("开始排盘")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGradient)
                        .cornerRadius(12)
                        .shadow(color: ZiWeiColors.primary.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("紫微斗数-点亮星空版")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.timeInputMode) { _ in
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.year) { _ in
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.month) { _ in
                viewModel.normalizeInput()
            }
            .onChange(of: viewModel.input.isLeapMonth) { _ in
                viewModel.normalizeInput()
            }
            .navigationDestination(isPresented: $showChartView) {
                ChartDisplayView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - 子视图
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.primaryGradient)
            
            Text("紫微斗数-点亮星空版")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(ZiWeiColors.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            
            Text("紫微斗数 · 四柱八字")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func inputCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(ZiWeiColors.textDark)
            
            content()
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}
