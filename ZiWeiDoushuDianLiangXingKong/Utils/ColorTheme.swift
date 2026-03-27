// ColorTheme.swift - 配色主题
// 看盘啦 · 配色与主题（部分取自原 Android APK）

import SwiftUI

/// 紫微排盘配色（参考 iztro 生态文档的「典籍/专业」观感：暖纸底、深字、琥珀强调）
struct ZiWeiColors {
    // 主色调
    static let primary = Color(red: 246/255, green: 109/255, blue: 18/255)
    static let textDark = Color(red: 73/255, green: 52/255, blue: 46/255)
    /// 次级说明文字
    static let textMuted = Color(red: 120/255, green: 108/255, blue: 98/255)
    static let border = Color(red: 200/255, green: 188/255, blue: 170/255)
    static let background = Color(red: 219/255, green: 210/255, blue: 194/255)
    static let gold = Color(red: 195/255, green: 168/255, blue: 126/255)
    /// 输入页与卡片用的浅表面（略亮于 background）
    static let cardSurface = Color(red: 252/255, green: 249/255, blue: 242/255)
    /// 盘面网格与宫格底色（仿宣纸/排盘纸）
    static let chartPaper = Color(red: 255/255, green: 252/255, blue: 246/255)
    /// 盘面外框线（古铜细线）
    static let chartFrame = Color(red: 176/255, green: 148/255, blue: 110/255)
    
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
    
    // 宫名颜色（朱砂，避免纯红刺眼）
    static let gongNameColor = Color(red: 176/255, green: 48/255, blue: 42/255)
    
    // 大限颜色
    static let daXianColor = Color(red: 130/255, green: 130/255, blue: 130/255)
    
    // 命宫高亮
    static let mingGongHighlight = Color(red: 172/255, green: 205/255, blue: 101/255).opacity(0.3)
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
    
    /// 输入页顶部「夜空」渐变：深蓝 + 轻微琥珀高光，与主按钮色呼应
    static let inputHeroGradient = LinearGradient(
        colors: [
            Color(red: 22/255, green: 28/255, blue: 48/255),
            Color(red: 38/255, green: 48/255, blue: 78/255),
            Color(red: 52/255, green: 62/255, blue: 96/255),
            Color(red: 72/255, green: 58/255, blue: 88/255).opacity(0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 整页背景：顶侧略冷、向下暖到纸色，层次更柔和
    static let screenBackdropGradient = LinearGradient(
        colors: [
            Color(red: 228/255, green: 232/255, blue: 248/255),
            Color(red: 242/255, green: 236/255, blue: 226/255),
            Color(red: 234/255, green: 228/255, blue: 216/255),
            Color(red: 248/255, green: 244/255, blue: 236/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - ZiWeiColors 与 AppColors 渐变对齐（供视图统一引用）

extension ZiWeiColors {
    static let inputHeroGradient = AppColors.inputHeroGradient
    static let screenBackdropGradient = AppColors.screenBackdropGradient
}

// MARK: - 界面修饰

extension View {
    /// 输入页全屏背景
    func ziWeiInputBackdrop() -> some View {
        background(ZiWeiColors.screenBackdropGradient.ignoresSafeArea())
    }

    /// 导航栏半透明材质，与暖纸背景协调
    func ziWeiNavigationChrome() -> some View {
        toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

// MARK: - 星曜 / 四化展示（供多处视图复用）

enum ChartPalette {
    static func starColor(_ star: Star) -> Color {
        switch star.category {
        case .zhengYao: return ZiWeiColors.zhengYaoColor
        case .fuXing: return ZiWeiColors.fuXingColor
        case .shaXing: return ZiWeiColors.shaXingColor
        case .zaYao: return ZiWeiColors.zaYaoColor
        case .liuNian: return ZiWeiColors.daXianColor
        }
    }

    static func huaColor(_ hua: String) -> Color {
        switch hua {
        case "化禄": return ZiWeiColors.huaLuColor
        case "化权": return ZiWeiColors.huaQuanColor
        case "化科": return ZiWeiColors.huaKeColor
        case "化忌": return ZiWeiColors.huaJiColor
        default: return .primary
        }
    }

    static func huaShortText(_ hua: String) -> String {
        switch hua {
        case "化禄": return "禄"
        case "化权": return "权"
        case "化科": return "科"
        case "化忌": return "忌"
        default: return ""
        }
    }
}
