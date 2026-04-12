// ColorTheme.swift - 配色主题
// 看盘啦 · 配色与主题（文墨天机 顶级深色/夜间琉璃质感重构）

import SwiftUI

/// 紫微排盘配色（重塑为文墨天机深色模式：深邃夜空底、高对比亮色星曜、琉璃质感）
struct ZiWeiColors {
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in trait.userInterfaceStyle == .dark ? dark : light })
    }

    // 主色调
    static let primary = dynamic(
        light: UIColor(red: 220/255, green: 160/255, blue: 0/255, alpha: 1),
        dark: UIColor(red: 247/255, green: 181/255, blue: 0/255, alpha: 1)
    )
    static let textDark = dynamic(light: .black, dark: .white)
    static let textMuted = dynamic(light: .systemGray, dark: .systemGray)
    static let border = dynamic(
        light: UIColor(white: 0.85, alpha: 1),
        dark: UIColor(red: 50/255, green: 50/255, blue: 54/255, alpha: 1)
    )
    static let background = dynamic(
        light: UIColor(white: 0.96, alpha: 1),
        dark: UIColor(red: 10/255, green: 10/255, blue: 12/255, alpha: 1)
    )
    
    /// 输入页与卡片表面
    static let cardSurface = dynamic(
        light: UIColor(white: 1.0, alpha: 0.85),
        dark: UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 0.85)
    )
    
    /// 盘面网格与宫格底色
    static let chartPaper = dynamic(
        light: .white,
        dark: UIColor(red: 20/255, green: 22/255, blue: 28/255, alpha: 1)
    )
    /// 盘面外框线
    static let chartFrame = dynamic(
        light: UIColor(white: 0.7, alpha: 1),
        dark: UIColor(red: 155/255, green: 138/255, blue: 106/255, alpha: 1)
    )
    
    // 星曜分类颜色
    static let zhengYaoColor = dynamic(
        light: UIColor(red: 200/255, green: 30/255, blue: 30/255, alpha: 1),
        dark: UIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1)
    )
    static let fuXingColor = dynamic(
        light: UIColor.systemBlue,
        dark: UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
    )
    static let shaXingColor = dynamic(light: .systemGray, dark: .systemGray)
    static let zaYaoColor = dynamic(light: .systemGray2, dark: .systemGray2)
    
    // 四化颜色
    static let huaLuColor = dynamic(light: .systemGreen, dark: UIColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 1))
    static let huaQuanColor = dynamic(light: .systemPurple, dark: UIColor(red: 191/255, green: 90/255, blue: 242/255, alpha: 1))
    static let huaKeColor = dynamic(light: .systemBlue, dark: UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1))
    static let huaJiColor = dynamic(light: .systemRed, dark: UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1))
    
    // 宫名颜色
    static let gongNameColor = textDark
    
    // 大限颜色
    static let daXianColor = dynamic(light: .systemOrange, dark: UIColor(red: 255/255, green: 159/255, blue: 10/255, alpha: 1))
    
    // 命宫高亮
    static let mingGongHighlight = dynamic(
        light: UIColor(white: 0.95, alpha: 1),
        dark: UIColor(white: 0.15, alpha: 1)
    )
    
    // 三方四正飞线与选中高亮（使用灰色）
    static let selectionCyan = dynamic(light: .systemGray3, dark: .systemGray)
    static let selectionFill = dynamic(light: UIColor(white: 0.92, alpha: 1), dark: UIColor(white: 0.25, alpha: 1))
    static let connectingLine = dynamic(light: .systemGray3, dark: .systemGray)
}

/// 深色与浅色模式适配的备用颜色
struct AppColors {
    static let inputHeroGradientLight = LinearGradient(
        colors: [
            Color(white: 0.95),
            Color(white: 0.98),
            Color(white: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let inputHeroGradientDark = LinearGradient(
        colors: [
            Color(red: 10/255, green: 12/255, blue: 20/255),
            Color(red: 18/255, green: 22/255, blue: 38/255),
            Color(red: 25/255, green: 30/255, blue: 50/255),
            Color(red: 20/255, green: 18/255, blue: 30/255).opacity(0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let screenBackdropGradientLight = LinearGradient(
        colors: [
            Color(white: 0.96),
            Color(white: 0.98),
            Color(white: 0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let screenBackdropGradientDark = LinearGradient(
        colors: [
            Color(red: 12/255, green: 12/255, blue: 14/255),
            Color(red: 18/255, green: 18/255, blue: 20/255),
            Color(red: 10/255, green: 10/255, blue: 12/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 界面修饰

struct ZiWeiInputBackdropModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content.background(
            Group {
                if colorScheme == .dark {
                    AppColors.screenBackdropGradientDark
                } else {
                    AppColors.screenBackdropGradientLight
                }
            }
            .ignoresSafeArea()
        )
    }
}

extension View {
    /// 输入页全屏背景
    func ziWeiInputBackdrop() -> some View {
        modifier(ZiWeiInputBackdropModifier())
    }

    /// 导航栏半透明材质（自适应）
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
        case .liuNian: return Color(red: 100/255, green: 210/255, blue: 255/255) // 明亮的流光青，凸显套盘流年星
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
