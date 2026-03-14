// TrueSolarTime.swift - 真太阳时修正
// 紫微星语 iOS 版

import Foundation

/// 真太阳时转换工具
struct TrueSolarTime {
    
    /// 计算真太阳时
    /// - Parameters:
    ///   - year: 公历年
    ///   - month: 公历月
    ///   - day: 公历日
    ///   - hour: 钟表时（0-23）
    ///   - minute: 分钟
    ///   - longitude: 经度（东经为正）
    ///   - standardMeridian: 标准时区经度（中国为120°E）
    /// - Returns: 真太阳时的(小时, 分钟)
    static func calculate(year: Int, month: Int, day: Int,
                          hour: Int, minute: Int,
                          longitude: Double,
                          standardMeridian: Double = 120.0) -> (hour: Int, minute: Int) {
        // 1. 经度时差修正（每度4分钟）
        let longitudeCorrection = (longitude - standardMeridian) * 4.0 // 分钟
        
        // 2. 均时差修正
        let eot = equationOfTime(year: year, month: month, day: day)
        
        // 3. 计算真太阳时
        let totalMinutes = Double(hour * 60 + minute) + longitudeCorrection + eot
        
        var correctedMinutes = Int(round(totalMinutes))
        // 处理溢出
        if correctedMinutes < 0 { correctedMinutes += 1440 }
        if correctedMinutes >= 1440 { correctedMinutes -= 1440 }
        
        return (hour: correctedMinutes / 60, minute: correctedMinutes % 60)
    }
    
    /// 均时差（Equation of Time）
    /// 简化公式，精度约±30秒
    static func equationOfTime(year: Int, month: Int, day: Int) -> Double {
        // 计算一年中的第几天
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = calendar.date(from: components) else { return 0 }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // B = (360/365) * (dayOfYear - 81) 度
        let B = (2.0 * Double.pi / 365.0) * Double(dayOfYear - 81)
        
        // 均时差（分钟）
        let eot = 9.87 * sin(2 * B) - 7.53 * cos(B) - 1.5 * sin(B)
        
        return eot
    }
    
    /// 将钟表时间转为真太阳时并返回完整信息
    static func convert(year: Int, month: Int, day: Int,
                        hour: Int, minute: Int,
                        longitude: Double) -> TrueSolarTimeResult {
        let longitudeCorrection = (longitude - 120.0) * 4.0
        let eot = equationOfTime(year: year, month: month, day: day)
        let result = calculate(year: year, month: month, day: day,
                             hour: hour, minute: minute, longitude: longitude)
        
        return TrueSolarTimeResult(
            originalHour: hour,
            originalMinute: minute,
            trueSolarHour: result.hour,
            trueSolarMinute: result.minute,
            longitudeCorrection: longitudeCorrection,
            equationOfTime: eot,
            totalCorrection: longitudeCorrection + eot
        )
    }
}

/// 真太阳时计算结果
struct TrueSolarTimeResult {
    let originalHour: Int
    let originalMinute: Int
    let trueSolarHour: Int
    let trueSolarMinute: Int
    let longitudeCorrection: Double  // 经度修正（分钟）
    let equationOfTime: Double       // 均时差（分钟）
    let totalCorrection: Double      // 总修正（分钟）
    
    var formattedOriginal: String {
        String(format: "%02d:%02d", originalHour, originalMinute)
    }
    
    var formattedTrueSolar: String {
        String(format: "%02d:%02d", trueSolarHour, trueSolarMinute)
    }
    
    var correctionDescription: String {
        let sign = totalCorrection >= 0 ? "+" : ""
        return String(format: "%@%.1f分钟", sign, totalCorrection)
    }
}
