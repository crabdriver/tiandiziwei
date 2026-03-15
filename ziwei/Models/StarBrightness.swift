// StarBrightness.swift - 星曜庙旺利陷表
// 紫微星语 iOS 版
// 数据来源：紫微斗数古籍标准亮度表

import Foundation

/// 星曜亮度等级
enum Brightness: String, CaseIterable {
    case miao = "庙"    // 最旺
    case wang = "旺"
    case de = "得"
    case li = "利"
    case ping = "平"
    case bu = "不"
    case xian = "陷"    // 最弱
    
    /// 数值表示（用于分析比较）
    var value: Int {
        switch self {
        case .miao: return 7
        case .wang: return 6
        case .de: return 5
        case .li: return 4
        case .ping: return 3
        case .bu: return 2
        case .xian: return 1
        }
    }
}

/// 星曜亮度查询（对齐 APK 编码表）
struct StarBrightnessTable {
    static let apkEncodedTable: [String: String] = [
        "紫微": "777666776666",
        "天府": "777676676667",
        "天梁": "667671761671",
        "天机": "767674112236",
        "贪狼": "677761142266",
        "天相": "667751111146",
        "左辅": "776663333337",
        "右弼": "777772221117",
        "太阳": "113777776421",
        "廉贞": "126777773231",
        "火星": "117666761321",
        "七杀": "667656677677",
        "武曲": "675477657777",
        "擎羊": "455444337773",
        "太阴": "774121115667",
        "巨门": "776521116767",
        "破军": "776677776667",
        "天同": "775521115657",
        "地空": "774432116777",
        "地劫": "777777777777",
        "铃星": "755474777777",
        "文昌": "455444337774",
        "文曲": "777677173616",
        "禄存": "607607607607",
        "天马": "006002006003",
        "天魁": "660700700006",
        "天钺": "006006067700",
        "红鸾": "716776617616",
        "天喜": "617617716716",
        "天刑": "317731311771",
        "天姚": "136713361771",
        "天哭": "373734137233",
        "天虚": "176716317613",
        "天官": "003666770336",
        "天福": "306306307707",
        "截空": "121317777700",
        "副截": "121317777700",
        "旬空": "131317717713",
        "副旬": "131317717713",
        "三台": "173173673763",
        "八座": "177367637737",
        "恩光": "373773763172",
        "天贵": "763663761763",
        "天伤": "133133113336",
        "天使": "113313333116",
        "天才": "637617637617",
        "天寿": "376173366376",
        "龙池": "633771273716",
        "凤阁": "737617312776",
        "天德": "773376673273",
        "解神": "737776732672",
        "年解": "737776732672",
        "孤辰": "003001003001",
        "寡宿": "030010030010",
        "华盖": "010070010030",
        "劫煞": "003001003001",
        "咸池": "100300100300",
        "天空": "131377716613",
        "大耗": "631231631231",
        "破碎": "010001000300"
    ]

    static let brightnessByDigit: [Character: String] = [
        "1": "陷",
        "2": "不",
        "3": "平",
        "4": "利",
        "5": "得",
        "6": "旺",
        "7": "庙"
    ]
    
    /// 查询星曜在某地支的亮度
    static func brightness(star: String, zhiIndex: Int) -> String? {
        guard let row = apkEncodedTable[star], zhiIndex >= 0, zhiIndex < 12 else { return nil }
        let chars = Array(row)
        guard zhiIndex < chars.count else { return nil }
        return brightnessByDigit[chars[zhiIndex]]
    }
    
    /// 查询星曜在某地支的亮度等级
    static func brightnessLevel(star: String, zhiIndex: Int) -> Brightness? {
        guard let str = brightness(star: star, zhiIndex: zhiIndex) else { return nil }
        return Brightness(rawValue: str)
    }
}
