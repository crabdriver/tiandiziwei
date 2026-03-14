// ChartViewModel.swift - 排盘视图模型
// 紫微星语 iOS 版

import Foundation
import SwiftUI

/// 排盘输入参数
struct ChartInput: Equatable {
    var year: Int = 1990
    var month: Int = 1
    var day: Int = 1
    var hour: Int = 12
    var minute: Int = 0
    var isMale: Bool = true
    var isLunar: Bool = false      // 是否为阴历输入
    var isLeapMonth: Bool = false  // 是否闰月
    var longitude: Double = 120.0  // 经度（用于真太阳时）
    var useTrueSolar: Bool = true  // 是否使用真太阳时
    var name: String = ""          // 姓名
    var eventNote: String = ""     // 事项备注
}

/// 主视图模型
class ChartViewModel: ObservableObject {
    @Published var input = ChartInput()
    @Published var ziWeiChart: ZiWeiChart?
    @Published var baZiChart: BaZiChart?
    @Published var isChartGenerated = false
    @Published var currentTab: ChartTab = .ziWei
    
    enum ChartTab {
        case ziWei   // 紫微盘
        case baZi    // 八字盘
        case tools   // 工具集
    }
    
    /// 生成排盘
    func generateChart() {
        // 1. 紫微排盘
        ziWeiChart = ZiWeiEngine.generateChart(
            year: input.year,
            month: input.month,
            day: input.day,
            hour: input.hour,
            minute: input.minute,
            isMale: input.isMale,
            longitude: input.longitude
        )
        
        // 2. 八字排盘
        if let chart = ziWeiChart {
            baZiChart = BaZiEngine.generateChart(
                lunar: chart.lunarDate,
                isMale: input.isMale
            )
        }
        
        isChartGenerated = true
    }
    
    /// 获取当前时间参数
    func setCurrentTime() {
        let now = Date()
        let calendar = Calendar.current
        input.year = calendar.component(.year, from: now)
        input.month = calendar.component(.month, from: now)
        input.day = calendar.component(.day, from: now)
        input.hour = calendar.component(.hour, from: now)
        input.minute = calendar.component(.minute, from: now)
    }
    
    /// 获取时辰显示文字
    func shiChenText(for hour: Int) -> String {
        let shiChenNames = ["子时(23-1)", "丑时(1-3)", "寅时(3-5)", "卯时(5-7)",
                           "辰时(7-9)", "巳时(9-11)", "午时(11-13)", "未时(13-15)",
                           "申时(15-17)", "酉时(17-19)", "戌时(19-21)", "亥时(21-23)"]
        let idx = LunarCalendarConverter.hourToShiChen(hour)
        return shiChenNames[idx]
    }
}
