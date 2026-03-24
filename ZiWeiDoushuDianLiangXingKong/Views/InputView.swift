// InputView.swift - 输入页面
// 紫微斗数-点亮星空版 iOS 版

import SwiftUI

/// 出生信息输入页面
struct InputView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var showChartView = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 顶部标题区域
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.primaryGradient)
                            Text("紫微斗数-点亮星空版")
                                .font(.title3.bold())
                                .foregroundColor(ZiWeiColors.textDark)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // 基本信息
                Section(header: Text("基本信息")) {
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
                }
                
                // 出生时间
                Section(header: Text("出生时间")) {
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
                }
                
                // 高级设置
                Section(header: Text("高级设置")) {
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
                }
                
                // 排盘按钮
                Section {
                    Button(action: {
                        viewModel.generateChart()
                        showChartView = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "sparkles")
                            Text("开始排盘")
                                .font(.headline)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(AppColors.primaryGradient)
                }
            }
            .navigationTitle("输入信息")
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
}
