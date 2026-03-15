// LunarCalendar.swift - 阴阳历转换核心算法
// 紫微星语 iOS 版

import Foundation

/// 阴历日期结构
struct LunarDate {
    var year: Int
    var month: Int
    var day: Int
    var isLeapMonth: Bool
    var yearGanZhi: String  // 年干支
    var monthGanZhi: String // 月干支
    var dayGanZhi: String   // 日干支
    var hourGanZhi: String  // 时干支
    var yearGan: String     // 年干
    var yearZhi: String     // 年支
    var monthGan: String    // 月干
    var monthZhi: String    // 月支
    var dayGan: String      // 日干
    var dayZhi: String      // 日支
    var hourGan: String     // 时干
    var hourZhi: String     // 时支
    var hourZhiIndex: Int   // 时支索引(0-11)
}

/// 阳历日期结构
struct SolarDate {
    var year: Int
    var month: Int
    var day: Int
}

/// 天干
let tianGan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]

/// 地支
let diZhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

/// 六十甲子
let jiaZi: [String] = {
    var result: [String] = []
    for i in 0..<60 {
        result.append(tianGan[i % 10] + diZhi[i % 12])
    }
    return result
}()

/// 六十甲子纳音五行
let naYinWuXing: [String: String] = [
    "甲子": "海中金", "乙丑": "海中金",
    "丙寅": "炉中火", "丁卯": "炉中火",
    "戊辰": "大林木", "己巳": "大林木",
    "庚午": "路旁土", "辛未": "路旁土",
    "壬申": "剑锋金", "癸酉": "剑锋金",
    "甲戌": "山头火", "乙亥": "山头火",
    "丙子": "涧下水", "丁丑": "涧下水",
    "戊寅": "城头土", "己卯": "城头土",
    "庚辰": "白蜡金", "辛巳": "白蜡金",
    "壬午": "杨柳木", "癸未": "杨柳木",
    "甲申": "泉中水", "乙酉": "泉中水",
    "丙戌": "屋上土", "丁亥": "屋上土",
    "戊子": "霹雳火", "己丑": "霹雳火",
    "庚寅": "松柏木", "辛卯": "松柏木",
    "壬辰": "长流水", "癸巳": "长流水",
    "甲午": "沙中金", "乙未": "沙中金",
    "丙申": "山下火", "丁酉": "山下火",
    "戊戌": "平地木", "己亥": "平地木",
    "庚子": "壁上土", "辛丑": "壁上土",
    "壬寅": "金箔金", "癸卯": "金箔金",
    "甲辰": "覆灯火", "乙巳": "覆灯火",
    "丙午": "天河水", "丁未": "天河水",
    "戊申": "大驿土", "己酉": "大驿土",
    "庚戌": "钗钏金", "辛亥": "钗钏金",
    "壬子": "桑柘木", "癸丑": "桑柘木",
    "甲寅": "大溪水", "乙卯": "大溪水",
    "丙辰": "沙中土", "丁巳": "沙中土",
    "戊午": "天上火", "己未": "天上火",
    "庚申": "石榴木", "辛酉": "石榴木",
    "壬戌": "大海水", "癸亥": "大海水"
]

// MARK: - 阴历数据表 (1900-2100年)
// 每年用一个十六进制数表示：
// 低4位表示闰月月份(0表示无闰月)
// 第5-16位表示12个月的大小月(1为大月30天，0为小月29天)
// 第17-20位表示闰月的大小(如果有闰月)
let lunarData: [Int] = [
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
    0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
    0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
    0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
    0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
    0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
    0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0,
    0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
    0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
    0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
    0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
    0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
    0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
    0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
    0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
    0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252,
    0x0d520
]

/// 阴阳历转换类
class LunarCalendarConverter {
    private static let gregorianTimeZone = TimeZone(secondsFromGMT: 8 * 3600)!
    private static let utcTimeZone = TimeZone(secondsFromGMT: 0)!
    private static let solarTermMinutes = [
        0, 21208, 42467, 63836, 85337, 107014,
        128867, 150921, 173149, 195551, 218072, 240693,
        263343, 285989, 308563, 331033, 353350, 375494,
        397447, 419210, 440795, 462224, 483532, 504758
    ]

    private static var chineseCalendar: Calendar {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = gregorianTimeZone
        return calendar
    }

    private static var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = gregorianTimeZone
        return calendar
    }

    private static var utcGregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        return calendar
    }

    private static func lunarYearFromChinese(era: Int, cyclicalYear: Int) -> Int {
        1924 + (era - 77) * 60 + (cyclicalYear - 1)
    }

    private static func chineseCycle(for lunarYear: Int) -> (era: Int, year: Int) {
        let offset = lunarYear - 1924
        let era = 77 + Int(floor(Double(offset) / 60.0))
        let year = ((offset % 60) + 60) % 60 + 1
        return (era, year)
    }
    
    // MARK: - 公历转阴历
    
    /// 获取阴历年份的总天数
    static func lunarYearDays(_ year: Int) -> Int {
        let idx = year - 1900
        guard idx >= 0, idx < lunarData.count else { return 365 }
        var sum = 348
        var info = lunarData[idx]
        for i in stride(from: 0x8000, through: 0x8, by: -1) {
            if (info & i) != 0 {
                sum += 1
            }
            info = lunarData[idx] // reset info for next iteration
        }
        // 修正：重新计算
        var total = 348
        let data = lunarData[idx]
        for i in 0..<12 {
            if (data & (0x10000 >> i)) != 0 {
                total += 1 // 大月30天 vs 小月29天
            }
        }
        return total + leapDays(year)
    }
    
    /// 获取闰月的天数
    static func leapDays(_ year: Int) -> Int {
        let idx = year - 1900
        guard idx >= 0, idx < lunarData.count else { return 0 }
        if leapMonth(year) != 0 {
            return (lunarData[idx] & 0x10000) != 0 ? 30 : 29
        }
        return 0
    }
    
    /// 获取闰月月份（0表示无闰月）
    static func leapMonth(_ year: Int) -> Int {
        let idx = year - 1900
        guard idx >= 0, idx < lunarData.count else { return 0 }
        return lunarData[idx] & 0xf
    }
    
    /// 获取某月天数
    static func monthDays(_ year: Int, _ month: Int) -> Int {
        let idx = year - 1900
        guard idx >= 0, idx < lunarData.count else { return 29 }
        return (lunarData[idx] & (0x10000 >> month)) != 0 ? 30 : 29
    }
    
    /// 公历转阴历
    static func solarToLunar(year: Int, month: Int, day: Int) -> LunarDate {
        let calendar = gregorianCalendar
        let chinese = chineseCalendar

        var targetComponents = DateComponents()
        targetComponents.year = year
        targetComponents.month = month
        targetComponents.day = day
        targetComponents.hour = 12
        let targetDate = calendar.date(from: targetComponents)!

        let chineseComponents = chinese.dateComponents(
            [.era, .year, .month, .day, .isLeapMonth],
            from: targetDate
        )

        let lunarYear = lunarYearFromChinese(
            era: chineseComponents.era ?? 77,
            cyclicalYear: chineseComponents.year ?? 1
        )
        let lunarMonth = chineseComponents.month ?? 1
        let lunarDay = chineseComponents.day ?? 1
        let isLeap = chineseComponents.isLeapMonth ?? false
        
        // 计算干支
        let ganZhiResult = calculateGanZhi(year: year, month: month, day: day,
                                            lunarYear: lunarYear, lunarMonth: lunarMonth)
        
        return LunarDate(
            year: lunarYear,
            month: lunarMonth,
            day: lunarDay,
            isLeapMonth: isLeap,
            yearGanZhi: ganZhiResult.yearGZ,
            monthGanZhi: ganZhiResult.monthGZ,
            dayGanZhi: ganZhiResult.dayGZ,
            hourGanZhi: ganZhiResult.hourGZ,
            yearGan: ganZhiResult.yearGan,
            yearZhi: ganZhiResult.yearZhi,
            monthGan: ganZhiResult.monthGan,
            monthZhi: ganZhiResult.monthZhi,
            dayGan: ganZhiResult.dayGan,
            dayZhi: ganZhiResult.dayZhi,
            hourGan: ganZhiResult.hourGan,
            hourZhi: ganZhiResult.hourZhi,
            hourZhiIndex: ganZhiResult.hourZhiIndex
        )
    }

    /// 阴历转公历
    static func lunarToSolar(year: Int, month: Int, day: Int, isLeapMonth: Bool) -> SolarDate? {
        guard year >= 1900, year <= 2100, month >= 1, month <= 12 else { return nil }

        let chinese = chineseCalendar
        let calendar = gregorianCalendar
        let cycle = chineseCycle(for: year)

        var components = DateComponents()
        components.calendar = chinese
        components.timeZone = gregorianTimeZone
        components.era = cycle.era
        components.year = cycle.year
        components.month = month
        components.day = day
        components.isLeapMonth = isLeapMonth
        components.hour = 12

        guard let solarDate = chinese.date(from: components) else { return nil }

        let solarComponents = calendar.dateComponents([.year, .month, .day], from: solarDate)
        guard let solarYear = solarComponents.year,
              let solarMonth = solarComponents.month,
              let solarDay = solarComponents.day else {
            return nil
        }

        return SolarDate(year: solarYear, month: solarMonth, day: solarDay)
    }
    
    // MARK: - 干支计算
    
    struct GanZhiResult {
        var yearGZ: String
        var monthGZ: String
        var dayGZ: String
        var hourGZ: String
        var yearGan: String
        var yearZhi: String
        var monthGan: String
        var monthZhi: String
        var dayGan: String
        var dayZhi: String
        var hourGan: String
        var hourZhi: String
        var hourZhiIndex: Int
    }
    
    static func calculateGanZhi(year: Int, month: Int, day: Int,
                                 lunarYear: Int, lunarMonth: Int) -> GanZhiResult {
        // 年干支（以立春为界）
        let yearOffset = lunarYear - 4
        let yearGanIdx = yearOffset % 10
        let yearZhiIdx = yearOffset % 12
        let yGan = tianGan[(yearGanIdx + 10) % 10]
        let yZhi = diZhi[(yearZhiIdx + 12) % 12]
        
        // 日干支
        // 按 APK 真值样本回推，1900-01-01 对应甲戌日，而不是庚子日。
        // 这里统一固定到东八区公历日界，避免系统时区影响整日差。
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = gregorianTimeZone
        var baseComp = DateComponents()
        baseComp.year = 1900
        baseComp.month = 1
        baseComp.day = 1
        let base = calendar.date(from: baseComp)!
        var targetComp = DateComponents()
        targetComp.year = year
        targetComp.month = month
        targetComp.day = day
        let target = calendar.date(from: targetComp)!
        let daysDiff = calendar.dateComponents([.day], from: base, to: target).day!
        // 1900年1月1日是甲戌日 (甲子=0, 甲戌=10)
        let dayGanZhiIdx = (daysDiff + 10) % 60
        let dGanIdx = ((dayGanZhiIdx % 10) + 10) % 10
        let dZhiIdx = ((dayGanZhiIdx % 12) + 12) % 12
        let dGan = tianGan[dGanIdx]
        let dZhi = diZhi[dZhiIdx]
        
        // 月干支
        let monthZhiIdx = (lunarMonth + 1) % 12  // 正月建寅
        let mZhi = diZhi[monthZhiIdx]
        // 年干决定月干起始
        let mGanStart = (yearGanIdx % 5) * 2 + 2
        let mGanIdx = (mGanStart + lunarMonth - 1) % 10
        let mGan = tianGan[mGanIdx]
        
        // 时干支（根据当前小时简化处理，默认为子时，需实际小时传入）
        let hourZhiIdx = 0 // 默认子时，实际需根据出生小时计算
        let hZhi = diZhi[hourZhiIdx]
        // 日干决定时干
        let hGanStart = (dGanIdx % 5) * 2
        let hGanIdx = (hGanStart + hourZhiIdx) % 10
        let hGan = tianGan[hGanIdx]
        
        return GanZhiResult(
            yearGZ: yGan + yZhi,
            monthGZ: mGan + mZhi,
            dayGZ: dGan + dZhi,
            hourGZ: hGan + hZhi,
            yearGan: yGan, yearZhi: yZhi,
            monthGan: mGan, monthZhi: mZhi,
            dayGan: dGan, dayZhi: dZhi,
            hourGan: hGan, hourZhi: hZhi,
            hourZhiIndex: hourZhiIdx
        )
    }
    
    /// 将小时转换为时辰索引
    static func hourToShiChen(_ hour: Int) -> Int {
        // 23-1:子(0), 1-3:丑(1), 3-5:寅(2), ...
        return ((hour + 1) / 2) % 12
    }

    private static func solarTermDate(year: Int, termIndex: Int) -> Date {
        let calendar = utcGregorianCalendar
        var baseComponents = DateComponents()
        baseComponents.year = 1900
        baseComponents.month = 1
        baseComponents.day = 6
        baseComponents.hour = 2
        baseComponents.minute = 5
        let baseDate = calendar.date(from: baseComponents)!
        let seconds = 31556925.9747 * Double(year - 1900) + Double(solarTermMinutes[termIndex]) * 60.0
        return baseDate.addingTimeInterval(seconds)
    }

    private static func solarMonthIndex(year: Int, month: Int, day: Int) -> Int {
        let calendar = gregorianCalendar
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let targetDate = calendar.date(from: components)!

        let xiaoHan = solarTermDate(year: year, termIndex: 0)
        let liChun = solarTermDate(year: year, termIndex: 2)
        let jingZhe = solarTermDate(year: year, termIndex: 4)
        let qingMing = solarTermDate(year: year, termIndex: 6)
        let liXia = solarTermDate(year: year, termIndex: 8)
        let mangZhong = solarTermDate(year: year, termIndex: 10)
        let xiaoShu = solarTermDate(year: year, termIndex: 12)
        let liQiu = solarTermDate(year: year, termIndex: 14)
        let baiLu = solarTermDate(year: year, termIndex: 16)
        let hanLu = solarTermDate(year: year, termIndex: 18)
        let liDong = solarTermDate(year: year, termIndex: 20)
        let daXue = solarTermDate(year: year, termIndex: 22)

        if targetDate < xiaoHan { return 11 }   // 子月
        if targetDate < liChun { return 12 }    // 丑月
        if targetDate < jingZhe { return 1 }    // 寅月
        if targetDate < qingMing { return 2 }   // 卯月
        if targetDate < liXia { return 3 }      // 辰月
        if targetDate < mangZhong { return 4 }  // 巳月
        if targetDate < xiaoShu { return 5 }    // 午月
        if targetDate < liQiu { return 6 }      // 未月
        if targetDate < baiLu { return 7 }      // 申月
        if targetDate < hanLu { return 8 }      // 酉月
        if targetDate < liDong { return 9 }     // 戌月
        if targetDate < daXue { return 10 }     // 亥月
        return 11                               // 子月
    }

    private static func solarYearForMonthPillar(year: Int, month: Int, day: Int) -> Int {
        let calendar = gregorianCalendar
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let targetDate = calendar.date(from: components)!
        let liChun = solarTermDate(year: year, termIndex: 2)
        return targetDate < liChun ? year - 1 : year
    }

    /// 根据公历日期重算某个农历月序下的月干支
    static func recalculateMonthGanZhi(
        solarYear: Int,
        solarMonth: Int,
        solarDay: Int,
        lunarYear: Int,
        lunarMonth: Int
    ) -> (ganZhi: String, gan: String, zhi: String) {
        _ = lunarYear
        _ = lunarMonth

        let monthIndex = solarMonthIndex(year: solarYear, month: solarMonth, day: solarDay)
        let branchOrder = ["寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥", "子", "丑"]
        let branch = branchOrder[monthIndex - 1]

        let effectiveYear = solarYearForMonthPillar(year: solarYear, month: solarMonth, day: solarDay)
        let yearGanIdx = ((effectiveYear - 4) % 10 + 10) % 10
        let firstMonthGanIdx = ((yearGanIdx % 5) * 2 + 2) % 10
        let ganIdx = (firstMonthGanIdx + monthIndex - 1) % 10
        let gan = tianGan[ganIdx]

        return (gan + branch, gan, branch)
    }
}
