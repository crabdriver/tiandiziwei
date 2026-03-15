// BaZiEngine.swift - 四柱八字排盘引擎
// 紫微斗数-点亮星空版 iOS 版
// 数据表直接提取自 Android 版 bazipaipan.java

import Foundation

// MARK: - 八字数据模型

/// 四柱信息
struct BaZiPillar {
    var tianGan: String   // 天干
    var diZhi: String     // 地支
    var ganZhi: String    // 干支组合
    var shiShen: String   // 十神
    var naYin: String     // 纳音
    var changSheng: String // 长生十二宫
    var hiddenGan: [String] // 地支藏干
}

/// 八字排盘结果
struct BaZiChart {
    var yearPillar: BaZiPillar    // 年柱
    var monthPillar: BaZiPillar   // 月柱
    var dayPillar: BaZiPillar     // 日柱 (日主)
    var hourPillar: BaZiPillar    // 时柱
    var shenSha: [String]         // 神煞列表
    var dayMaster: String         // 日主
    var daYun: [(age: Int, ganZhi: String)]  // 大运
    var wuXingStrength: [String: Int] // 五行力量
}

// MARK: - 八字排盘引擎

class BaZiEngine {
    
    // MARK: - 十神对照表（从 bazipaipan.java 提取）
    
    /// 日主对应的十神表: shiShenTable[日干][其他天干索引]
    static let shiShenTable: [String: [String]] = [
        "甲": ["比肩", "劫财", "食神", "伤官", "偏财", "正财", "七杀", "正官", "偏印", "正印"],
        "乙": ["劫财", "比肩", "伤官", "食神", "正财", "偏财", "正官", "七杀", "正印", "偏印"],
        "丙": ["偏印", "正印", "比肩", "劫财", "食神", "伤官", "偏财", "正财", "七杀", "正官"],
        "丁": ["正印", "偏印", "劫财", "比肩", "伤官", "食神", "正财", "偏财", "正官", "七杀"],
        "戊": ["七杀", "正官", "偏印", "正印", "比肩", "劫财", "食神", "伤官", "偏财", "正财"],
        "己": ["正官", "七杀", "正印", "偏印", "劫财", "比肩", "伤官", "食神", "正财", "偏财"],
        "庚": ["偏财", "正财", "七杀", "正官", "偏印", "正印", "比肩", "劫财", "食神", "伤官"],
        "辛": ["正财", "偏财", "正官", "七杀", "正印", "偏印", "劫财", "比肩", "伤官", "食神"],
        "壬": ["食神", "伤官", "偏财", "正财", "七杀", "正官", "偏印", "正印", "比肩", "劫财"],
        "癸": ["伤官", "食神", "正财", "偏财", "正官", "七杀", "正印", "偏印", "劫财", "比肩"]
    ]
    
    // MARK: - 地支藏干表（从 bazipaipan.java 提取）
    
    static let hiddenGanTable: [String: [String]] = [
        "子": ["癸"],
        "丑": ["己", "癸", "辛"],
        "寅": ["甲", "丙", "戊"],
        "卯": ["乙"],
        "辰": ["戊", "乙", "癸"],
        "巳": ["丙", "庚", "戊"],
        "午": ["丁", "己"],
        "未": ["己", "丁", "乙"],
        "申": ["庚", "壬", "戊"],
        "酉": ["辛"],
        "戌": ["戊", "辛", "丁"],
        "亥": ["壬", "甲"]
    ]
    
    // MARK: - 十二长生表（从 bazipaipan.java 提取）
    
    static let changShengNames = ["长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝", "胎", "养"]
    
    /// 十天干的十二长生位置（地支排列：子丑寅卯辰巳午未申酉戌亥）
    static let changShengTable: [String: [String]] = [
        "甲": ["沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝", "胎", "养", "长生"],
        "乙": ["病", "衰", "帝旺", "临官", "冠带", "沐浴", "长生", "养", "胎", "绝", "墓", "死"],
        "丙": ["胎", "养", "长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝"],
        "丁": ["绝", "墓", "死", "病", "衰", "帝旺", "临官", "冠带", "沐浴", "长生", "养", "胎"],
        "戊": ["胎", "养", "长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝"],
        "己": ["绝", "墓", "死", "病", "衰", "帝旺", "临官", "冠带", "沐浴", "长生", "养", "胎"],
        "庚": ["死", "墓", "绝", "胎", "养", "长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病"],
        "辛": ["长生", "养", "胎", "绝", "墓", "死", "病", "衰", "帝旺", "临官", "冠带", "沐浴"],
        "壬": ["帝旺", "衰", "病", "死", "墓", "绝", "胎", "养", "长生", "沐浴", "冠带", "临官"],
        "癸": ["临官", "冠带", "沐浴", "长生", "养", "胎", "绝", "墓", "死", "病", "衰", "帝旺"]
    ]
    
    // MARK: - 神煞表（从 bazipaipan.java 提取的核心部分）
    
    /// 天乙贵人
    static let tianYiGuiRen: [String: [String]] = [
        "甲": ["丑", "未"], "乙": ["子", "申"], "丙": ["亥", "酉"],
        "丁": ["亥", "酉"], "戊": ["丑", "未"], "己": ["子", "申"],
        "庚": ["午", "寅"], "辛": ["午", "寅"], "壬": ["卯", "巳"],
        "癸": ["卯", "巳"]
    ]
    
    /// 文昌星
    static let wenChang: [String: String] = [
        "甲": "巳", "乙": "午", "丙": "申", "丁": "酉",
        "戊": "申", "己": "酉", "庚": "亥", "辛": "子",
        "壬": "寅", "癸": "卯"
    ]
    
    /// 羊刃
    static let yangRen: [String: String] = [
        "甲": "卯", "乙": "寅", "丙": "午", "丁": "巳",
        "戊": "午", "己": "巳", "庚": "酉", "辛": "申",
        "壬": "子", "癸": "亥"
    ]
    
    /// 禄神
    static let luShen: [String: String] = [
        "甲": "寅", "乙": "卯", "丙": "巳", "丁": "午",
        "戊": "巳", "己": "午", "庚": "申", "辛": "酉",
        "壬": "亥", "癸": "子"
    ]
    
    /// 驿马
    static let yiMa: [String: String] = [
        "子": "寅", "丑": "亥", "寅": "申", "卯": "巳",
        "辰": "寅", "巳": "亥", "午": "申", "未": "巳",
        "申": "寅", "酉": "亥", "戌": "申", "亥": "巳"
    ]
    
    /// 华盖
    static let huaGai: [String: String] = [
        "子": "辰", "丑": "丑", "寅": "戌", "卯": "未",
        "辰": "辰", "巳": "丑", "午": "戌", "未": "未",
        "申": "辰", "酉": "丑", "戌": "戌", "亥": "未"
    ]
    
    /// 咸池（桃花）
    static let xianChi: [String: String] = [
        "子": "酉", "丑": "午", "寅": "卯", "卯": "子",
        "辰": "酉", "巳": "午", "午": "卯", "未": "子",
        "申": "酉", "酉": "午", "戌": "卯", "亥": "子"
    ]
    
    // MARK: - 五行配色
    
    /// 五行对应颜色名
    static func wuXingElement(_ char: String) -> String {
        if "甲乙寅卯".contains(char) { return "木" }
        if "丙丁巳午".contains(char) { return "火" }
        if "戊己丑辰未戌".contains(char) { return "土" }
        if "庚辛申酉".contains(char) { return "金" }
        if "壬癸亥子".contains(char) { return "水" }
        return ""
    }
    
    // MARK: - 计算十神
    
    static func getShiShen(dayGan: String, otherGan: String) -> String {
        guard let table = shiShenTable[dayGan],
              let ganIdx = tianGan.firstIndex(of: otherGan) else { return "" }
        return table[ganIdx]
    }
    
    /// 十神简称
    static func shiShenShort(_ shiShen: String) -> String {
        switch shiShen {
        case "比肩": return "比"
        case "劫财": return "劫"
        case "食神": return "食"
        case "伤官": return "伤"
        case "偏财": return "才"
        case "正财": return "财"
        case "七杀": return "杀"
        case "正官": return "官"
        case "偏印": return "枭"
        case "正印": return "印"
        default: return ""
        }
    }
    
    // MARK: - 计算长生
    
    static func getChangSheng(dayGan: String, forZhi: String) -> String {
        guard let table = changShengTable[dayGan],
              let zhiIdx = diZhi.firstIndex(of: forZhi) else { return "" }
        return table[zhiIdx]
    }
    
    // MARK: - 计算神煞
    
    static func calculateShenSha(dayGan: String, yearZhi: String, fourPillars: [String]) -> [String] {
        var result: [String] = []
        
        // 天乙贵人
        if let guiRenZhi = tianYiGuiRen[dayGan] {
            for pillar in fourPillars {
                for zhi in guiRenZhi {
                    if pillar.contains(zhi) {
                        result.append("天乙贵人(\(zhi))")
                    }
                }
            }
        }
        
        // 文昌
        if let wcZhi = wenChang[dayGan] {
            for pillar in fourPillars {
                if pillar.contains(wcZhi) {
                    result.append("文昌(\(wcZhi))")
                }
            }
        }
        
        // 羊刃
        if let yrZhi = yangRen[dayGan] {
            for pillar in fourPillars {
                if pillar.contains(yrZhi) {
                    result.append("羊刃(\(yrZhi))")
                }
            }
        }
        
        // 禄神
        if let lsZhi = luShen[dayGan] {
            for pillar in fourPillars {
                if pillar.contains(lsZhi) {
                    result.append("禄神(\(lsZhi))")
                }
            }
        }
        
        // 驿马
        if let ymZhi = yiMa[yearZhi] {
            for pillar in fourPillars {
                if pillar.contains(ymZhi) {
                    result.append("驿马(\(ymZhi))")
                }
            }
        }
        
        // 华盖
        if let hgZhi = huaGai[yearZhi] {
            for pillar in fourPillars {
                if pillar.contains(hgZhi) {
                    result.append("华盖(\(hgZhi))")
                }
            }
        }
        
        // 桃花
        if let xcZhi = xianChi[yearZhi] {
            for pillar in fourPillars {
                if pillar.contains(xcZhi) {
                    result.append("咸池(\(xcZhi))")
                }
            }
        }
        
        return result
    }
    
    // MARK: - 计算五行力量
    
    static func calculateWuXingStrength(fourPillars: [(gan: String, zhi: String)]) -> [String: Int] {
        var strength: [String: Int] = ["金": 0, "木": 0, "水": 0, "火": 0, "土": 0]
        
        // 天干力量值
        let ganStrength = 36
        // 地支力量值(根据藏干分配)
        
        for pillar in fourPillars {
            let ganElement = wuXingElement(pillar.gan)
            strength[ganElement, default: 0] += ganStrength
            
            if let hidden = hiddenGanTable[pillar.zhi] {
                let weights: [Int]
                switch hidden.count {
                case 1: weights = [100]
                case 2: weights = [70, 30]
                case 3: weights = [60, 30, 10]
                default: weights = []
                }
                
                for (idx, hGan) in hidden.enumerated() {
                    let elem = wuXingElement(hGan)
                    if idx < weights.count {
                        strength[elem, default: 0] += weights[idx]
                    }
                }
            }
        }
        
        return strength
    }
    
    // MARK: - 主排盘方法
    
    static func generateChart(lunar: LunarDate, isMale: Bool) -> BaZiChart {
        let dayGan = lunar.dayGan
        let yearZhi = lunar.yearZhi
        
        // 构建四柱
        func makePillar(gan: String, zhi: String) -> BaZiPillar {
            let gz = gan + zhi
            return BaZiPillar(
                tianGan: gan,
                diZhi: zhi,
                ganZhi: gz,
                shiShen: getShiShen(dayGan: dayGan, otherGan: gan),
                naYin: naYinWuXing[gz] ?? "",
                changSheng: getChangSheng(dayGan: dayGan, forZhi: zhi),
                hiddenGan: hiddenGanTable[zhi] ?? []
            )
        }
        
        let yearPillar = makePillar(gan: lunar.yearGan, zhi: lunar.yearZhi)
        let monthPillar = makePillar(gan: lunar.monthGan, zhi: lunar.monthZhi)
        let dayPillar = makePillar(gan: lunar.dayGan, zhi: lunar.dayZhi)
        var hourPillar = makePillar(gan: lunar.hourGan, zhi: lunar.hourZhi)
        hourPillar.shiShen = "" // 日主不看自己的十神
        
        // 四柱地支列表
        let fourZhi = [lunar.yearZhi, lunar.monthZhi, lunar.dayZhi, lunar.hourZhi]
        
        // 计算神煞
        let shenSha = calculateShenSha(dayGan: dayGan, yearZhi: yearZhi, fourPillars: fourZhi)
        
        // 计算五行力量
        let pillars = [(lunar.yearGan, lunar.yearZhi),
                       (lunar.monthGan, lunar.monthZhi),
                       (lunar.dayGan, lunar.dayZhi),
                       (lunar.hourGan, lunar.hourZhi)]
        let wuXingStrength = calculateWuXingStrength(fourPillars: pillars)
        
        return BaZiChart(
            yearPillar: yearPillar,
            monthPillar: monthPillar,
            dayPillar: dayPillar,
            hourPillar: hourPillar,
            shenSha: shenSha,
            dayMaster: dayGan,
            daYun: [], // TODO: 大运计算
            wuXingStrength: wuXingStrength
        )
    }
}
