// ColorTheme.swift - 配色主题
// 紫微斗数-点亮星空版 iOS 版 - 颜色从原 Android 版提取

import SwiftUI

/// 紫微排盘配色
struct ZiWeiColors {
    // 主色调
    static let primary = Color(red: 246/255, green: 109/255, blue: 18/255)
    static let textDark = Color(red: 73/255, green: 52/255, blue: 46/255)
    static let border = Color(red: 217/255, green: 215/255, blue: 215/255)
    static let background = Color(red: 219/255, green: 210/255, blue: 194/255)
    static let gold = Color(red: 195/255, green: 168/255, blue: 126/255)
    
    // 星曜分类颜色
    static let zhengYaoColor = Color(red: 13/255, green: 80/255, blue: 148/255)   // 蓝
    static let fuXingColor = Color(red: 62/255, green: 139/255, blue: 64/255)     // 绿
    static let shaXingColor = Color(red: 217/255, green: 29/255, blue: 30/255)    // 红
    static let zaYaoColor = Color(red: 129/255, green: 0/255, blue: 127/255)      // 紫
    
    // 四化颜色
    static let huaLuColor = Color(red: 46/255, green: 152/255, blue: 152/255)     // 青
    static let huaQuanColor = Color(red: 152/255, green: 64/255, blue: 146/255)   // 紫
    static let huaKeColor = Color(red: 62/255, green: 139/255, blue: 64/255)      // 绿
    static let huaJiColor = Color(red: 217/255, green: 29/255, blue: 30/255)      // 红
    
    // 宫名颜色
    static let gongNameColor = Color.red
    
    // 大限颜色
    static let daXianColor = Color(red: 130/255, green: 130/255, blue: 130/255)
    
    // 命宫高亮
    static let mingGongHighlight = Color(red: 172/255, green: 205/255, blue: 101/255).opacity(0.3)
}

/// 八字排盘五行配色
struct BaZiColors {
    // 五行颜色（从 bazipaipan.java 提取）
    static let wood = Color(red: 1/255, green: 127/255, blue: 2/255)       // 木-绿
    static let fire = Color(red: 233/255, green: 9/255, blue: 7/255)       // 火-红
    static let earth = Color(red: 202/255, green: 107/255, blue: 39/255)   // 土-黄
    static let metal = Color(red: 11/255, green: 121/255, blue: 234/255)   // 金-蓝
    static let water = Color(red: 34/255, green: 34/255, blue: 34/255)     // 水-黑
    
    /// 根据天干/地支获取五行颜色
    static func colorFor(_ char: String) -> Color {
        if "甲乙寅卯".contains(char) { return wood }
        if "丙丁巳午".contains(char) { return fire }
        if "戊己丑辰未戌".contains(char) { return earth }
        if "庚辛申酉".contains(char) { return metal }
        if "壬癸亥子".contains(char) { return water }
        return .primary
    }
}

/// 深色模式颜色适配
struct AppColors {
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    
    // 渐变色
    static let headerGradient = LinearGradient(
        colors: [
            Color(red: 139/255, green: 69/255, blue: 19/255),
            Color(red: 195/255, green: 168/255, blue: 126/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 246/255, green: 109/255, blue: 18/255),
            Color(red: 255/255, green: 165/255, blue: 0/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
