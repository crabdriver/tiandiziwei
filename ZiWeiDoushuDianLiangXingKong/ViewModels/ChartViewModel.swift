// ChartViewModel.swift - 排盘视图模型
// 紫微斗数-点亮星空版 iOS 版

import Foundation
import SwiftUI

enum TimeInputMode: String, CaseIterable {
    case clockTime
    case trueSolarTime
    case lunarTime

    var title: String {
        switch self {
        case .clockTime: return "北京时间"
        case .trueSolarTime: return "真太阳时"
        case .lunarTime: return "阴历时间"
        }
    }

    var apkCode: String {
        switch self {
        case .clockTime: return "1"
        case .trueSolarTime: return "2"
        case .lunarTime: return "3"
        }
    }
}

/// 排盘输入参数
struct ChartInput: Equatable {
    var year: Int = 1990
    var month: Int = 1
    var day: Int = 1
    var hour: Int = 12
    var minute: Int = 0
    var isMale: Bool = true
    var timeInputMode: TimeInputMode = .clockTime
    var isLeapMonth: Bool = false  // 是否闰月
    var useMonthAdjustment: Bool = false // 是否换月
    var longitude: Double = 120.0  // 经度（用于真太阳时）
    var name: String = ""          // 姓名
    var eventNote: String = ""     // 事项备注

    var apkGenderCode: String {
        isMale ? "1" : "2"
    }

    var apkLongitudeString: String {
        String(format: "%.1f", longitude)
    }

    var apkPayloadString: String {
        let base = [
            timeInputMode.apkCode,
            String(year),
            String(month),
            String(day),
            String(hour),
            String(minute),
            "0",
            apkLongitudeString,
            "-8",
            apkGenderCode,
            useMonthAdjustment ? "1" : "0"
        ]

        if timeInputMode == .lunarTime {
            return (base + [isLeapMonth ? "1" : "0"]).joined(separator: "|")
        }

        return base.joined(separator: "|")
    }

    func apkFullString(prefix: String = "input") -> String {
        "\(prefix)#\(apkPayloadString)"
    }

    static func fromApkString(_ raw: String) -> ChartInput? {
        let payload = raw.contains("#") ? String(raw.split(separator: "#", maxSplits: 1)[1]) : raw
        let parts = payload.split(separator: "|").map(String.init)
        guard parts.count == 11 || parts.count == 12 else { return nil }

        let mode: TimeInputMode
        switch parts[0] {
        case "1": mode = .clockTime
        case "2": mode = .trueSolarTime
        case "3": mode = .lunarTime
        default: return nil
        }

        guard let year = Int(parts[1]),
              let month = Int(parts[2]),
              let day = Int(parts[3]),
              let hour = Int(parts[4]),
              let minute = Int(parts[5]),
              let longitude = Double(parts[7]) else {
            return nil
        }

        return ChartInput(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            isMale: parts[9] == "1",
            timeInputMode: mode,
            isLeapMonth: parts.count == 12 ? parts[11] == "1" : false,
            useMonthAdjustment: parts[10] == "1",
            longitude: longitude
        )
    }
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
        normalizeInput()

        // 1. 紫微排盘
        ziWeiChart = ZiWeiEngine.generateChart(
            year: input.year,
            month: input.month,
            day: input.day,
            hour: input.hour,
            minute: input.minute,
            isMale: input.isMale,
            timeInputMode: input.timeInputMode,
            isLeapMonth: input.isLeapMonth,
            useMonthAdjustment: input.useMonthAdjustment,
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

    /// 当前输入条件下的有效日数
    func availableDays() -> [Int] {
        let maxDay: Int
        if input.timeInputMode == .lunarTime {
            maxDay = input.isLeapMonth
                ? LunarCalendarConverter.leapDays(input.year)
                : LunarCalendarConverter.monthDays(input.year, input.month)
        } else {
            var components = DateComponents()
            components.year = input.year
            components.month = input.month
            let calendar = Calendar(identifier: .gregorian)
            let date = calendar.date(from: components) ?? Date()
            maxDay = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        }
        return Array(1...max(1, maxDay))
    }

    /// 根据阴历年份自动约束闰月与日期
    func normalizeInput() {
        if input.timeInputMode == .lunarTime {
            let leapMonth = LunarCalendarConverter.leapMonth(input.year)
            if input.isLeapMonth && leapMonth != input.month {
                input.isLeapMonth = false
            }
        } else {
            input.isLeapMonth = false
        }

        let validDays = availableDays()
        if let maxDay = validDays.last, input.day > maxDay {
            input.day = maxDay
        }
    }

    func hasLeapMonthForCurrentSelection() -> Bool {
        input.timeInputMode == .lunarTime && LunarCalendarConverter.leapMonth(input.year) == input.month
    }

    func usesLongitudeCorrection() -> Bool {
        input.timeInputMode != .lunarTime
    }
}
