// ZiWeiEngine.swift - 紫微斗数排盘核心引擎
// 看盘啦 · iOS 紫微斗数排盘

import Foundation

// MARK: - 数据模型

/// 紫微星曜
struct Star {
    let name: String
    let category: StarCategory
    var brightness: String? // 庙/旺/得/利/平/不/陷
    var siHua: String?      // 化禄/化权/化科/化忌
    
    enum StarCategory {
        case zhengYao    // 十四正曜
        case fuXing      // 辅星（左辅右弼文昌文曲）
        case shaXing     // 煞星（擎羊陀罗火星铃星地空地劫）
        case zaYao       // 杂曜
        case liuNian     // 流年星
    }
}

/// 十二宫
struct Palace {
    let name: String        // 宫名: 命宫/兄弟宫/...
    let position: String    // 地支位置: 子/丑/...
    let tianGan: String     // 宫干
    var stars: [Star]       // 宫内星曜
    var daXian: String      // 大限范围
    var xiaoXian: String    // 小限
    var changSheng: String  // 长生十二宫
    // 流年系列
    var suiQian: String     // 岁前星
    var jiangQian: String   // 将前星
    var boshi: String       // 博士星
    var gongTransforms: [PalaceTransform] // 宫干四化
    var chongHua: [PalaceTransform]       // 冲化
    var ziHua: [PalaceTransform]          // 自化
}

struct PalaceTransform {
    let star: String
    let hua: String
    let targetPosition: String
    let targetPalace: String
    let strength: Int
}

/// 紫微排盘结果
struct ZiWeiChart {
    var palaces: [Palace]            // 十二宫
    var mingGong: String             // 命宫所在地支
    var mingGongIdx: Int             // 命宫地支索引
    var shenGong: String             // 身宫所在地支
    var shenGongIdx: Int             // 身宫地支索引
    var wuXingJu: String             // 五行局
    var wuXingJuNum: Int             // 五行局数字
    var mingZhu: String              // 命主
    var shenZhu: String              // 身主
    var lunarDate: LunarDate         // 阴历日期
    var trueSolarTime: String        // 真太阳时
    var clockTime: String            // 钟表时间
    var flowYearGanZhi: String       // 当前流年干支
    var liuDou: String               // 流斗
    var laiYinGong: String           // 来因宫
    var lunarMonthCount: Int         // APK `农历月计数`
    var layer2Gong: String?          // APK `层2.1`，由 native libziweixingyu.so 计算，iOS 版暂不实现
    var layer3Gong: String?          // APK `层3.1`，由 native libziweixingyu.so 计算，iOS 版暂不实现
    var nominalAge: Int              // 当前虚岁
    var siHuaInfo: [String: String]  // 四化信息
    var isMale: Bool                 // 性别
    var isShun: Bool                 // 大限是否顺行
    var timeInputMode: TimeInputMode // 时间输入模式
    var useMonthAdjustment: Bool     // 是否启用换月
}

// MARK: - 紫微斗数排盘引擎

class ZiWeiEngine {
    
    // MARK: - 常量定义
    
    /// 十四正曜
    static let zhengYao14 = [
        "紫微", "天机", "太阳", "武曲", "天同", "廉贞",
        "天府", "太阴", "贪狼", "巨门", "天相", "天梁", "七杀", "破军"
    ]
    
    /// 十二宫名称（按 APK 盘面顺序，从命宫起顺排）
    static let gongNames = [
        "命宫", "父母宫", "福德宫", "田宅宫", "官禄宫", "交友宫",
        "迁移宫", "疾厄宫", "财帛宫", "子女宫", "夫妻宫", "兄弟宫"
    ]
    
    /// 五行局名称对照
    static let wuXingJuName: [Int: String] = [
        2: "水二局", 3: "木三局", 4: "金四局", 5: "土五局", 6: "火六局"
    ]
    
    /// 命主对照表(年支 -> 命主)
    static let mingZhuTable: [String: String] = [
        "子": "贪狼", "丑": "巨门", "寅": "禄存", "卯": "文曲",
        "辰": "廉贞", "巳": "武曲", "午": "破军", "未": "武曲",
        "申": "廉贞", "酉": "文曲", "戌": "禄存", "亥": "巨门"
    ]
    
    /// 身主对照表(年支 -> 身主)
    static let shenZhuTable: [String: String] = [
        "子": "铃星", "丑": "天相", "寅": "天梁", "卯": "天同",
        "辰": "文昌", "巳": "天机", "午": "铃星", "未": "天相",
        "申": "天梁", "酉": "天同", "戌": "文昌", "亥": "天机"
    ]
    
    /// 紫微星安星表 - 根据五行局数和农历日安紫微星
    /// 返回紫微星所在的地支索引(0=子, 1=丑, ...)
    static func locateZiWei(juNum: Int, day: Int) -> Int {
        // 直接对齐 APK `zwpview.s(i3, i4)` 的规则：
        // 先看日数除五行局的余数；若不能整除，则补足到可整除，
        // 再按补足值奇偶决定前移还是后移，最后从寅宫起算。
        let remainder = day % juNum
        let offsetFromYin: Int

        if remainder == 0 {
            offsetFromYin = (day / juNum) - 1
        } else {
            let complement = juNum - remainder
            let divisibleQuotient = (day + complement) / juNum
            if complement % 2 == 0 {
                offsetFromYin = divisibleQuotient + complement - 1
            } else {
                offsetFromYin = divisibleQuotient - complement - 1
            }
        }

        return ((2 + offsetFromYin) % 12 + 12) % 12
    }
    
    /// 安紫微星系（紫微、天机、太阳、武曲、天同、廉贞）
    static func placeZiWeiSeries(ziWeiPos: Int) -> [String: Int] {
        var result: [String: Int] = [:]
        result["紫微"] = ziWeiPos
        // 紫微星系按固定间隔排列（逆时针）
        // 紫微 -> 天机(逆1) -> 空(逆2) -> 太阳(逆3) -> 武曲(逆4) -> 天同(逆5) -> 空(逆6) -> 空(逆7) -> 廉贞(逆8)
        result["天机"] = (ziWeiPos - 1 + 12) % 12
        result["太阳"] = (ziWeiPos - 3 + 12) % 12
        result["武曲"] = (ziWeiPos - 4 + 12) % 12
        result["天同"] = (ziWeiPos - 5 + 12) % 12
        result["廉贞"] = (ziWeiPos - 8 + 12) % 12
        return result
    }
    
    /// 安天府星系（天府、太阴、贪狼、巨门、天相、天梁、七杀、破军）
    static func placeTianFuSeries(ziWeiPos: Int) -> [String: Int] {
        var result: [String: Int] = [:]
        // 天府与紫微关于寅-申轴对称
        let tianFuPos = (4 - ziWeiPos + 12) % 12  // 寅宫为轴
        result["天府"] = tianFuPos
        // 天府星系顺时针排列
        result["太阴"] = (tianFuPos + 1) % 12
        result["贪狼"] = (tianFuPos + 2) % 12
        result["巨门"] = (tianFuPos + 3) % 12
        result["天相"] = (tianFuPos + 4) % 12
        result["天梁"] = (tianFuPos + 5) % 12
        result["七杀"] = (tianFuPos + 6) % 12
        // 破军: 天府之后第10位
        result["破军"] = (tianFuPos + 10) % 12
        return result
    }

    static func zhiIndex(from pattern: String, at index: Int) -> Int {
        let chars = Array(pattern)
        guard index >= 0, index < chars.count else { return 0 }
        return diZhi.firstIndex(of: String(chars[index])) ?? 0
    }

    static func xunKongPair(for ganZhi: String) -> (first: Int, second: Int)? {
        guard let index = jiaZi.firstIndex(of: ganZhi) else { return nil }
        switch index / 10 {
        case 0: return (10, 11) // 戌亥
        case 1: return (8, 9)   // 申酉
        case 2: return (6, 7)   // 午未
        case 3: return (4, 5)   // 辰巳
        case 4: return (2, 3)   // 寅卯
        case 5: return (0, 1)   // 子丑
        default: return nil
        }
    }
    
    /// 安辅星
    static func placeAuxiliaryStars(lunar: LunarDate, lunarMonthCount: Int) -> [String: Int] {
        var result: [String: Int] = [:]
        let monthIdx = lunarMonthCount - 1
        let hourIdx = lunar.hourZhiIndex
        let yearZhiIdx = diZhi.firstIndex(of: lunar.yearZhi)!
        let yearGanIdx = tianGan.firstIndex(of: lunar.yearGan)!
        
        // 左辅: 从辰宫起正月，顺行
        result["左辅"] = (4 + monthIdx) % 12
        // 右弼: 从戌宫起正月，逆行
        result["右弼"] = (10 - monthIdx + 12) % 12
        result["天刑"] = (9 + monthIdx) % 12
        result["天姚"] = (1 + monthIdx) % 12
        result["阴煞"] = zhiIndex(from: "寅子戌申午辰寅子戌申午辰", at: monthIdx)
        result["天月"] = zhiIndex(from: "戌巳辰寅未卯亥未寅午戌寅", at: monthIdx)
        result["天巫"] = zhiIndex(from: "巳申寅亥巳申寅亥巳申寅亥", at: monthIdx)
        result["解神"] = zhiIndex(from: "申申戌戌子子寅寅辰辰午午", at: monthIdx)
        
        // 文昌: 从戌宫起子时，逆行
        result["文昌"] = (10 - hourIdx + 12) % 12
        // 文曲: 从辰宫起子时，顺行
        result["文曲"] = (4 + hourIdx) % 12
        result["台辅"] = (6 + hourIdx) % 12
        result["封诰"] = (2 + hourIdx) % 12
        
        // 禄存: 根据年干
        let luCunPos = [2, 3, 5, 6, 5, 6, 8, 9, 11, 0] // 甲寅乙卯丙巳...
        result["禄存"] = luCunPos[yearGanIdx]
        
        // 擎羊: 禄存前一位
        result["擎羊"] = (luCunPos[yearGanIdx] + 1) % 12
        // 陀罗: 禄存后一位
        result["陀罗"] = (luCunPos[yearGanIdx] - 1 + 12) % 12
        
        // 火星: 根据年支和时支
        let huoXingBase = [2, 3, 1, 9, 2, 3, 1, 9, 2, 3, 1, 9]
        result["火星"] = (huoXingBase[yearZhiIdx] + hourIdx) % 12
        
        // 铃星: 根据年支和时支
        let lingXingBase = [10, 10, 3, 10, 10, 10, 3, 10, 10, 10, 3, 10]
        result["铃星"] = (lingXingBase[yearZhiIdx] + hourIdx) % 12
        
        // 地空: 从亥宫起子时逆行
        result["地空"] = (11 - hourIdx + 12) % 12
        // 地劫: 从亥宫起子时顺行
        result["地劫"] = (11 + hourIdx) % 12
        
        // 天魁天钺(根据年干)
        let tianKuiPos = [1, 0, 11, 9, 2, 8, 7, 6, 5, 3] // APK: 丑子亥酉寅申未午巳卯
        let tianYuePos = [7, 8, 9, 11, 6, 0, 1, 2, 3, 5] // APK: 未申酉亥午子丑寅卯巳
        result["天魁"] = tianKuiPos[yearGanIdx]
        result["天钺"] = tianYuePos[yearGanIdx]
        result["天官"] = zhiIndex(from: "未辰巳寅卯酉亥酉戌午", at: yearGanIdx)
        result["天福"] = zhiIndex(from: "酉申子亥卯寅午巳午巳", at: yearGanIdx)
        result["截空"] = zhiIndex(from: "申未辰卯子酉午巳寅丑", at: yearGanIdx)
        result["副截"] = zhiIndex(from: "酉午巳寅丑申未辰卯子", at: yearGanIdx)
        result["天厨"] = zhiIndex(from: "巳午子巳午申寅午酉亥", at: yearGanIdx)
        
        return result
    }
    
    /// 安杂曜
    static func placeMiscStars(
        lunar: LunarDate,
        mingGongIdx: Int,
        shenGongIdx: Int,
        auxiliaryStars: [String: Int]
    ) -> [String: Int] {
        var result: [String: Int] = [:]
        let yearZhiIdx = diZhi.firstIndex(of: lunar.yearZhi)!
        
        // 天马: 根据年支
        result["天马"] = zhiIndex(from: "寅亥申巳寅亥申巳寅亥申巳", at: yearZhiIdx)
        
        // 红鸾: 从卯宫起子年逆行
        result["红鸾"] = (3 - yearZhiIdx + 12) % 12
        // 天喜: 红鸾对宫
        result["天喜"] = (result["红鸾"]! + 6) % 12
        
        // APK 中天哭、天虚与旧实现方向相反
        result["天哭"] = (6 - yearZhiIdx + 12) % 12
        result["天虚"] = (6 + yearZhiIdx) % 12
        
        // 龙池: 从辰宫起子年顺行
        result["龙池"] = (4 + yearZhiIdx) % 12
        // 凤阁: 从戌宫起子年逆行
        result["凤阁"] = (10 - yearZhiIdx + 12) % 12
        
        // 华盖: 年支决定
        let huaGaiPos = [4, 1, 10, 7, 4, 1, 10, 7, 4, 1, 10, 7]
        result["华盖"] = huaGaiPos[yearZhiIdx]
        
        // 孤辰: 年支决定
        let guChenPos = [2, 2, 5, 5, 5, 8, 8, 8, 11, 11, 11, 2]
        result["孤辰"] = guChenPos[yearZhiIdx]
        
        // 寡宿: 年支决定
        result["寡宿"] = zhiIndex(from: "戌戌丑丑丑辰辰辰未未未戌", at: yearZhiIdx)
        result["劫煞"] = zhiIndex(from: "巳寅亥申巳寅亥申巳寅亥申", at: yearZhiIdx)
        result["咸池"] = zhiIndex(from: "酉午卯子酉午卯子酉午卯子", at: yearZhiIdx)
        result["破碎"] = zhiIndex(from: "巳丑酉巳丑酉巳丑酉巳丑酉", at: yearZhiIdx)
        result["大耗"] = zhiIndex(from: "未午酉申亥戌丑子卯寅巳辰", at: yearZhiIdx)
        result["蜚廉"] = zhiIndex(from: "申酉戌巳午未寅卯辰亥子丑", at: yearZhiIdx)
        result["天德"] = (9 + yearZhiIdx) % 12
        result["龙德"] = (yearZhiIdx + 7) % 12
        result["月德"] = (5 + yearZhiIdx) % 12
        result["年解"] = (10 - yearZhiIdx + 12) % 12
        result["天空"] = (yearZhiIdx + 1) % 12
        result["天才"] = (mingGongIdx + yearZhiIdx) % 12
        result["天寿"] = (shenGongIdx + yearZhiIdx) % 12
        result["天伤"] = (mingGongIdx + 5) % 12
        result["天使"] = (mingGongIdx + 7) % 12
        let dayOffset = lunar.day - 1
        if let zuoFuPos = auxiliaryStars["左辅"] {
            result["三台"] = (zuoFuPos + dayOffset) % 12
        }
        if let youBiPos = auxiliaryStars["右弼"] {
            result["八座"] = (youBiPos - dayOffset + 12 * 3) % 12
        }
        if let wenQuPos = auxiliaryStars["文曲"] {
            result["天贵"] = (wenQuPos + lunar.day - 2 + 12 * 3) % 12
        }
        if let wenChangPos = auxiliaryStars["文昌"] {
            result["恩光"] = (wenChangPos + lunar.day - 2 + 12 * 3) % 12
        }
        if let xunKong = xunKongPair(for: lunar.yearGanZhi) {
            let yearGanIdx = tianGan.firstIndex(of: lunar.yearGan) ?? 0
            if yearGanIdx % 2 == 0 {
                result["旬空"] = xunKong.first
                result["副旬"] = xunKong.second
            } else {
                result["副旬"] = xunKong.first
                result["旬空"] = xunKong.second
            }
        }
        
        return result
    }
    
    /// 四化飞星
    static func calculateSiHua(yearGan: String) -> [String: String] {
        // 四化表：年干 -> [化禄, 化权, 化科, 化忌]
        let siHuaTable: [String: [String]] = [
            "甲": ["廉贞", "破军", "武曲", "太阳"],
            "乙": ["天机", "天梁", "紫微", "太阴"],
            "丙": ["天同", "天机", "文昌", "廉贞"],
            "丁": ["太阴", "天同", "天机", "巨门"],
            "戊": ["贪狼", "太阴", "右弼", "天机"],
            "己": ["武曲", "贪狼", "天梁", "文曲"],
            "庚": ["太阳", "武曲", "太阴", "天同"],
            "辛": ["巨门", "太阳", "文曲", "文昌"],
            "壬": ["天梁", "紫微", "左辅", "武曲"],
            "癸": ["破军", "巨门", "太阴", "贪狼"]
        ]
        
        guard let stars = siHuaTable[yearGan] else { return [:] }
        
        return [
            stars[0]: "化禄",
            stars[1]: "化权",
            stars[2]: "化科",
            stars[3]: "化忌"
        ]
    }

    /// APK native `tools.getzwp()` 返回的宫干四化力度表。
    /// 目前先按已核对的完整命例固化为“星 + 化”固定值，
    /// 比此前用亮度线性换算更接近 APK 实际输出。
    static let siHuaStrengthTable: [String: Int] = [
        "廉贞|化禄": 10, "天机|化禄": 50, "天同|化禄": 99, "太阴|化禄": 40,
        "贪狼|化禄": 50, "武曲|化禄": 90, "太阳|化禄": 60, "巨门|化禄": 20,
        "天梁|化禄": 60, "破军|化禄": 50,

        "破军|化权": 10, "天梁|化权": 90, "天机|化权": 20, "天同|化权": 20,
        "太阴|化权": 90, "贪狼|化权": 90, "武曲|化权": 50, "太阳|化权": 20,
        "紫微|化权": 80, "巨门|化权": 90,

        "武曲|化科": 30, "紫微|化科": 90, "文昌|化科": 10, "天机|化科": 90,
        "右弼|化科": 10, "天梁|化科": 15, "太阴|化科": 95, "文曲|化科": 20,
        "左辅|化科": 10,

        "太阳|化忌": 80, "太阴|化忌": 20, "廉贞|化忌": 10, "巨门|化忌": 30,
        "天机|化忌": 95, "文曲|化忌": 30, "天同|化忌": 90, "文昌|化忌": 90,
        "武曲|化忌": 50, "贪狼|化忌": 30
    ]
    
    /// 确定命宫位置
    /// 命宫 = 从寅宫起正月顺数到生月，再从该宫逆数到生时
    static func locateMingGong(month: Int, hourIdx: Int) -> Int {
        let monthPos = (2 + month - 1) % 12  // 寅(2)起正月
        let mingPos = (monthPos - hourIdx + 12) % 12
        return mingPos
    }
    
    /// 确定身宫位置
    /// 身宫 = 从寅宫起正月顺数到生月，再从该宫顺数到生时
    static func locateShenGong(month: Int, hourIdx: Int) -> Int {
        let monthPos = (2 + month - 1) % 12
        let shenPos = (monthPos + hourIdx) % 12
        return shenPos
    }
    
    /// 安十二宫（按 APK 盘面从命宫起顺排地支）
    static func arrangePalaces(mingGongIdx: Int) -> [(name: String, zhiIdx: Int)] {
        var result: [(name: String, zhiIdx: Int)] = []
        for i in 0..<12 {
            let zhiIdx = (mingGongIdx + i) % 12
            result.append((name: gongNames[i], zhiIdx: zhiIdx))
        }
        return result
    }
    
    /// 安宫干（根据年干起甲）
    static func palaceTianGan(yearGanIdx: Int, zhiIdx: Int) -> String {
        // 年干决定寅宫天干：甲己年起丙寅，乙庚年起戊寅...
        let yinGanStart = [2, 4, 6, 8, 0] // 丙,戊,庚,壬,甲
        let start = yinGanStart[yearGanIdx % 5]
        // 从寅宫(2)到目标地支的顺时针步数
        let steps = (zhiIdx - 2 + 12) % 12
        let ganIdx = (start + steps) % 10
        return tianGan[ganIdx]
    }

    /// 根据命宫宫干支纳音计算五行局
    static func calculateWuXingJu(yearGanIdx: Int, mingGongIdx: Int) -> (num: Int, name: String) {
        let gongGan = palaceTianGan(yearGanIdx: yearGanIdx, zhiIdx: mingGongIdx)
        let gongZhi = diZhi[mingGongIdx]
        let naYin = naYinWuXing[gongGan + gongZhi] ?? ""

        let juNum: Int
        if naYin.contains("水") {
            juNum = 2
        } else if naYin.contains("木") {
            juNum = 3
        } else if naYin.contains("金") {
            juNum = 4
        } else if naYin.contains("土") {
            juNum = 5
        } else if naYin.contains("火") {
            juNum = 6
        } else {
            juNum = 2
        }

        return (juNum, wuXingJuName[juNum] ?? "水二局")
    }
    
    /// 计算 12 段大限年龄区间，真正挂到哪一宫由顺逆行决定。
    static func calculateDaXian(juNum: Int) -> [(start: Int, end: Int)] {
        var result: [(start: Int, end: Int)] = []
        for i in 0..<12 {
            let start = juNum + i * 10
            let end = start + 9
            result.append((start: start, end: end))
        }
        return result
    }
    
    /// 煞星名集合
    static let shaXingNames: Set<String> = ["擎羊", "陀罗", "火星", "铃星", "地空", "地劫"]
    
    /// 辅星名集合
    static let fuXingNames: Set<String> = ["左辅", "右弼", "文昌", "文曲", "天魁", "天钺", "禄存"]
    
    /// 长生十二宫名称
    static let changShengNames = ["长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝", "胎", "养"]
    
    /// 计算长生十二宫
    /// 阳男阴女从长生顺行，阴男阳女从长生逆行
    static func calculateChangSheng(juNum: Int, isShun: Bool) -> [Int: String] {
        // 五行局决定长生位置
        // 水二局→长生在申, 木三局→长生在亥, 金四局→长生在巳, 土五局→长生在申, 火六局→长生在寅
        let changShengStart: Int
        switch juNum {
        case 2: changShengStart = 8   // 水→申
        case 3: changShengStart = 11  // 木→亥
        case 4: changShengStart = 5   // 金→巳
        case 5: changShengStart = 8   // 土→申
        case 6: changShengStart = 2   // 火→寅
        default: changShengStart = 2
        }
        
        var result: [Int: String] = [:]
        for i in 0..<12 {
            let pos: Int
            if isShun {
                pos = (changShengStart + i) % 12
            } else {
                pos = (changShengStart - i + 12) % 12
            }
            result[pos] = changShengNames[i]
        }
        return result
    }
    
    /// 确定星曜分类
    static func categorize(_ starName: String) -> Star.StarCategory {
        if zhengYao14.contains(starName) { return .zhengYao }
        if shaXingNames.contains(starName) { return .shaXing }
        if fuXingNames.contains(starName) { return .fuXing }
        return .zaYao
    }

    /// APK 中的“换月”语义未完全还原。
    /// 根据已拿到的 A/B 样本，当前更接近 APK 的做法是：
    /// - 主盘骨架（四柱、命身宫、五行局等）仍按显示农历月
    /// - 仅月系辅曜/杂曜链路使用“换月后的月计数”
    static func adjustedLunarMonth(_ month: Int, useMonthAdjustment: Bool) -> Int {
        guard useMonthAdjustment else { return month }
        return month == 12 ? 1 : month + 1
    }

    static func advanceJiaZi(_ ganZhi: String, steps: Int) -> String {
        guard let index = jiaZi.firstIndex(of: ganZhi) else { return ganZhi }
        let safeIndex = ((index + steps) % 60 + 60) % 60
        return jiaZi[safeIndex]
    }

    static func calculateLiuDou(flowYearZhi: String, hourZhi: String, lunarMonthCount: Int) -> String {
        guard let hourIdx = diZhi.firstIndex(of: hourZhi) else { return "" }
        let base = shiftZhi(flowYearZhi, steps: hourIdx - lunarMonthCount)
        return shiftZhi(base, steps: 1)
    }

    static func shiftZhi(_ zhi: String, steps: Int) -> String {
        guard let index = diZhi.firstIndex(of: zhi) else { return zhi }
        let safeIndex = ((index + steps) % 12 + 12) % 12
        return diZhi[safeIndex]
    }

    static func oppositeZhi(_ zhi: String) -> String {
        shiftZhi(zhi, steps: 6)
    }

    /// APK 中 `其他信息.层1.1` 会在对应宫位旁标注“此为生年四化”。
    /// 由于每宫四化是按该宫宫干起化，因此可确定来因宫就是“宫干等于生年天干”的宫位。
    static func locateLaiYinGong(yearGan: String, palaces: [Palace], fallback: String) -> String {
        palaces.first(where: { $0.tianGan == yearGan })?.position ?? fallback
    }

    static let huaDisplayOrder: [String: Int] = [
        "化禄": 0,
        "化权": 1,
        "化科": 2,
        "化忌": 3
    ]

    // APK 每宫的“四化”是该宫向外飞出的宫干四化；
    // “自化/冲化”则是挂在当前宫星曜上的结果：
    // - 自化：本宫发化且落回本宫
    // - 冲化：对宫发化并飞入本宫
    static func palaceTransforms(
        palace: Palace,
        allPalaces: [Palace]
    ) -> [PalaceTransform] {
        let transformMap = calculateSiHua(yearGan: palace.tianGan)
        var transforms: [PalaceTransform] = []

        for (starName, hua) in transformMap {
            guard let targetPalace = allPalaces.first(where: { current in
                current.stars.contains(where: { $0.name == starName })
            }) else {
                continue
            }

            let strength = siHuaStrengthTable["\(starName)|\(hua)"] ?? {
                let targetZhiIdx = diZhi.firstIndex(of: targetPalace.position) ?? 0
                let brightness = StarBrightnessTable
                    .brightnessLevel(star: starName, zhiIndex: targetZhiIdx)?
                    .value ?? 3
                return Int((Double(brightness) / 7.0 * 100.0).rounded())
            }()

            transforms.append(
                PalaceTransform(
                    star: starName,
                    hua: hua,
                    targetPosition: targetPalace.position,
                    targetPalace: targetPalace.name,
                    strength: strength
                )
            )
        }

        transforms.sort {
            let lhsOrder = huaDisplayOrder[$0.hua] ?? .max
            let rhsOrder = huaDisplayOrder[$1.hua] ?? .max
            if lhsOrder == rhsOrder { return $0.star < $1.star }
            return lhsOrder < rhsOrder
        }
        return transforms
    }
    
    // MARK: - 主排盘方法
    
    /// 执行完整的紫微排盘
    static func generateChart(
        year: Int, month: Int, day: Int, hour: Int, minute: Int,
        isMale: Bool,
        timeInputMode: TimeInputMode = .clockTime,
        isLeapMonth: Bool = false,
        useMonthAdjustment: Bool = false,
        longitude: Double = 120.0,
        timeZone: Int = 8
    ) -> ZiWeiChart {
        _ = timeZone

        // 0. 将输入统一转换为公历日期
        let originalSolarDate: SolarDate
        let normalizedIsLeapMonth =
            timeInputMode == .lunarTime &&
            isLeapMonth &&
            LunarCalendarConverter.leapMonth(year) == month

        if timeInputMode == .lunarTime,
           let converted = LunarCalendarConverter.lunarToSolar(
               year: year,
               month: month,
               day: day,
               isLeapMonth: normalizedIsLeapMonth
           ) {
            originalSolarDate = converted
        } else {
            originalSolarDate = SolarDate(year: year, month: month, day: day)
        }

        // 1. 真太阳时修正
        let solarTimeResult = TrueSolarTime.convert(
            year: originalSolarDate.year,
            month: originalSolarDate.month,
            day: originalSolarDate.day,
            hour: hour,
            minute: minute,
            longitude: longitude
        )
        let clockTimeFromTrueSolar = TrueSolarTime.convertFromTrueSolar(
            year: originalSolarDate.year,
            month: originalSolarDate.month,
            day: originalSolarDate.day,
            hour: hour,
            minute: minute,
            longitude: longitude
        )

        let timeBasisSolarYear: Int
        let timeBasisSolarMonth: Int
        let timeBasisSolarDay: Int
        let timeBasisHour: Int
        let timeBasisMinute: Int

        switch timeInputMode {
        case .clockTime:
            timeBasisSolarYear = solarTimeResult.trueSolarYear
            timeBasisSolarMonth = solarTimeResult.trueSolarMonth
            timeBasisSolarDay = solarTimeResult.trueSolarDay
            timeBasisHour = solarTimeResult.trueSolarHour
            timeBasisMinute = solarTimeResult.trueSolarMinute
        case .trueSolarTime:
            timeBasisSolarYear = originalSolarDate.year
            timeBasisSolarMonth = originalSolarDate.month
            timeBasisSolarDay = originalSolarDate.day
            timeBasisHour = hour
            timeBasisMinute = minute
        case .lunarTime:
            timeBasisSolarYear = solarTimeResult.trueSolarYear
            timeBasisSolarMonth = solarTimeResult.trueSolarMonth
            timeBasisSolarDay = solarTimeResult.trueSolarDay
            timeBasisHour = solarTimeResult.trueSolarHour
            timeBasisMinute = solarTimeResult.trueSolarMinute
        }

        // 2. 公历转阴历
        var lunar = LunarCalendarConverter.solarToLunar(
            year: timeBasisSolarYear,
            month: timeBasisSolarMonth,
            day: timeBasisSolarDay
        )
        let rawChartYearGan = lunar.yearGan
        let rawChartYearZhi = lunar.yearZhi
        let displayLunarMonth = lunar.month
        let lunarMonthCount = adjustedLunarMonth(displayLunarMonth, useMonthAdjustment: useMonthAdjustment)
        let hourIdx = LunarCalendarConverter.hourToShiChen(timeBasisHour)
        lunar.hourZhiIndex = hourIdx
        lunar.hourZhi = diZhi[hourIdx]

        let pillarDayOffset = hourIdx == 0 ? 1 : 0
        var pillarCalendar = Calendar(identifier: .gregorian)
        pillarCalendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        var pillarComponents = DateComponents()
        pillarComponents.year = timeBasisSolarYear
        pillarComponents.month = timeBasisSolarMonth
        pillarComponents.day = timeBasisSolarDay
        let basePillarDate = pillarCalendar.date(from: pillarComponents)!
        let pillarDate = pillarCalendar.date(byAdding: .day, value: pillarDayOffset, to: basePillarDate)!
        let pillarDateComponents = pillarCalendar.dateComponents([.year, .month, .day], from: pillarDate)
        let pillarSolarYear = pillarDateComponents.year ?? timeBasisSolarYear
        let pillarSolarMonth = pillarDateComponents.month ?? timeBasisSolarMonth
        let pillarSolarDay = pillarDateComponents.day ?? timeBasisSolarDay

        let displayYearGanZhi = LunarCalendarConverter.recalculateYearGanZhi(
            solarYear: pillarSolarYear,
            solarMonth: pillarSolarMonth,
            solarDay: pillarSolarDay,
            solarHour: timeBasisHour,
            solarMinute: timeBasisMinute
        )
        lunar.yearGanZhi = displayYearGanZhi.ganZhi
        lunar.yearGan = displayYearGanZhi.gan
        lunar.yearZhi = displayYearGanZhi.zhi

        let monthGanZhi = LunarCalendarConverter.recalculateMonthGanZhi(
            solarYear: timeBasisSolarYear,
            solarMonth: timeBasisSolarMonth,
            solarDay: timeBasisSolarDay,
            solarHour: timeBasisHour,
            solarMinute: timeBasisMinute,
            lunarYear: lunar.year,
            lunarMonth: displayLunarMonth
        )
        lunar.monthGanZhi = monthGanZhi.ganZhi
        lunar.monthGan = monthGanZhi.gan
        lunar.monthZhi = monthGanZhi.zhi

        let dayGanZhi = LunarCalendarConverter.recalculateDayGanZhi(
            solarYear: pillarSolarYear,
            solarMonth: pillarSolarMonth,
            solarDay: pillarSolarDay
        )
        lunar.dayGanZhi = dayGanZhi.ganZhi
        lunar.dayGan = dayGanZhi.gan
        lunar.dayZhi = dayGanZhi.zhi
        
        // 重新计算时干
        let dayGanIdx = tianGan.firstIndex(of: lunar.dayGan)!
        let hGanStart = (dayGanIdx % 5) * 2
        let hGanIdx = (hGanStart + hourIdx) % 10
        lunar.hourGan = tianGan[hGanIdx]
        lunar.hourGanZhi = lunar.hourGan + lunar.hourZhi
        
        // 2. 确定命宫和身宫
        let mingGongIdx = locateMingGong(month: displayLunarMonth, hourIdx: hourIdx)
        let shenGongIdx = locateShenGong(month: displayLunarMonth, hourIdx: hourIdx)
        
        // 3. 确定五行局
        let chartYearGan = hourIdx == 0 ? displayYearGanZhi.gan : rawChartYearGan
        let chartYearZhi = hourIdx == 0 ? displayYearGanZhi.zhi : rawChartYearZhi
        let yearGanIdx = tianGan.firstIndex(of: chartYearGan)!
        let wuXingJu = calculateWuXingJu(yearGanIdx: yearGanIdx, mingGongIdx: mingGongIdx)
        let juNum = wuXingJu.num
        let juName = wuXingJu.name
        
        // 4. 安十二宫
        let palaceArrangement = arrangePalaces(mingGongIdx: mingGongIdx)
        
        // 5. 安紫微星
        let ziWeiPos = locateZiWei(juNum: juNum, day: lunar.day)
        let ziWeiSeries = placeZiWeiSeries(ziWeiPos: ziWeiPos)
        let tianFuSeries = placeTianFuSeries(ziWeiPos: ziWeiPos)
        
        // 6. 安辅星
        let auxStars = placeAuxiliaryStars(lunar: lunar, lunarMonthCount: lunarMonthCount)
        
        // 7. 安杂曜
        let miscStars = placeMiscStars(
            lunar: lunar,
            mingGongIdx: mingGongIdx,
            shenGongIdx: shenGongIdx,
            auxiliaryStars: auxStars
        )
        
        // 8. 计算四化
        let siHua = calculateSiHua(yearGan: chartYearGan)
        
        // 9. 大限方向
        let isYangGan = yearGanIdx % 2 == 0
        let isShun = (isMale && isYangGan) || (!isMale && !isYangGan)
        
        // 10. 计算大限
        let daXianList = calculateDaXian(juNum: juNum)
        
        // 11. 长生十二宫
        let changShengMap = calculateChangSheng(juNum: juNum, isShun: isShun)
        
        // 12. 流年星系
        let yearZhiIdx = diZhi.firstIndex(of: chartYearZhi)!
        let suiJianMap = FlowYearStars.placeSuiJian(yearZhiIdx: yearZhiIdx)
        let jiangQianMap = FlowYearStars.placeJiangQian(yearZhiIdx: yearZhiIdx)
        let luCunPos = auxStars["禄存"] ?? 0
        let boshiMap = FlowYearStars.placeBoshi(luCunPos: luCunPos, isShun: isShun)
        let currentYear = Calendar.current.component(.year, from: Date())
        let nominalAge = max(1, currentYear - lunar.year + 1)
        let xiaoXianPos = FlowYearStars.xiaoXianPosition(
            currentAge: nominalAge,
            isMale: isMale,
            yearZhiIdx: yearZhiIdx
        )
        let flowYearGanZhi = advanceJiaZi(lunar.yearGanZhi, steps: nominalAge - 1)
        let flowYearZhi = String(flowYearGanZhi.suffix(1))
        let liuDou = calculateLiuDou(
            flowYearZhi: flowYearZhi,
            hourZhi: lunar.hourZhi,
            lunarMonthCount: displayLunarMonth
        )
        
        // 13. 组装十二宫
        var palaces: [Palace] = []
        for (idx, arrangement) in palaceArrangement.enumerated() {
            let zhi = diZhi[arrangement.zhiIdx]
            let gongGan = palaceTianGan(yearGanIdx: yearGanIdx, zhiIdx: arrangement.zhiIdx)
            
            // 收集该宫的星曜
            var starsInPalace: [Star] = []
            
            // 添加正曜（紫微系+天府系）
            let allStarPositions = ziWeiSeries.merging(tianFuSeries) { _, new in new }
            for (starName, pos) in allStarPositions {
                if pos == arrangement.zhiIdx {
                    var star = Star(name: starName, category: .zhengYao)
                    star.brightness = StarBrightnessTable.brightness(star: starName, zhiIndex: arrangement.zhiIdx)
                    if let hua = siHua[starName] {
                        star.siHua = hua
                    }
                    starsInPalace.append(star)
                }
            }
            
            // 添加辅星和煞星
            for (starName, pos) in auxStars {
                if pos == arrangement.zhiIdx {
                    let category = categorize(starName)
                    var star = Star(name: starName, category: category)
                    star.brightness = StarBrightnessTable.brightness(star: starName, zhiIndex: arrangement.zhiIdx)
                    if let hua = siHua[starName] {
                        star.siHua = hua
                    }
                    starsInPalace.append(star)
                }
            }
            
            // 添加杂曜
            for (starName, pos) in miscStars {
                if pos == arrangement.zhiIdx {
                    var star = Star(name: starName, category: .zaYao)
                    star.brightness = StarBrightnessTable.brightness(star: starName, zhiIndex: arrangement.zhiIdx)
                    starsInPalace.append(star)
                }
            }
            
            let daXianIndex = isShun ? idx : (12 - idx) % 12
            let daXian = daXianIndex < daXianList.count ? "\(daXianList[daXianIndex].start)~\(daXianList[daXianIndex].end)" : ""
            
            // 长生
            let changSheng = changShengMap[arrangement.zhiIdx] ?? ""
            
            // 流年星
            let suiQian = suiJianMap[arrangement.zhiIdx] ?? ""
            let jiangQian = jiangQianMap[arrangement.zhiIdx] ?? ""
            let boshi = boshiMap[arrangement.zhiIdx] ?? ""
            
            let xiaoXian = arrangement.zhiIdx == xiaoXianPos ? "\(nominalAge)岁" : ""

            let palace = Palace(
                name: arrangement.name,
                position: zhi,
                tianGan: gongGan,
                stars: starsInPalace,
                daXian: daXian,
                xiaoXian: xiaoXian,
                changSheng: changSheng,
                suiQian: suiQian,
                jiangQian: jiangQian,
                boshi: boshi,
                gongTransforms: [],
                chongHua: [],
                ziHua: []
            )
            palaces.append(palace)
        }

        for idx in palaces.indices {
            palaces[idx].gongTransforms = palaceTransforms(palace: palaces[idx], allPalaces: palaces)
        }

        for idx in palaces.indices {
            let currentPosition = palaces[idx].position
            palaces[idx].ziHua = palaces[idx].gongTransforms.filter { $0.targetPosition == currentPosition }

            let oppositePosition = oppositeZhi(currentPosition)
            if let oppositePalace = palaces.first(where: { $0.position == oppositePosition }) {
                palaces[idx].chongHua = oppositePalace.gongTransforms.filter { $0.targetPosition == currentPosition }
            } else {
                palaces[idx].chongHua = []
            }
        }
        
        // 命主和身主
        let mingZhu = mingZhuTable[diZhi[mingGongIdx]] ?? ""
        let shenZhu = shenZhuTable[chartYearZhi] ?? ""
        let laiYinGong = locateLaiYinGong(
            yearGan: chartYearGan,
            palaces: palaces,
            fallback: diZhi[mingGongIdx]
        )
        
        // 真太阳时格式化
        let trueSolarTimeStr: String
        let clockTimeStr: String
        switch timeInputMode {
        case .clockTime, .lunarTime:
            trueSolarTimeStr = solarTimeResult.formattedTrueSolarDateTime
            clockTimeStr = String(
                format: "%d-%d-%d %02d:%02d",
                originalSolarDate.year,
                originalSolarDate.month,
                originalSolarDate.day,
                hour,
                minute
            )
        case .trueSolarTime:
            trueSolarTimeStr = String(
                format: "%d-%d-%d %02d:%02d",
                originalSolarDate.year,
                originalSolarDate.month,
                originalSolarDate.day,
                hour,
                minute
            )
            clockTimeStr = clockTimeFromTrueSolar.formattedOriginalDateTime
        }
        
        return ZiWeiChart(
            palaces: palaces,
            mingGong: diZhi[mingGongIdx],
            mingGongIdx: mingGongIdx,
            shenGong: diZhi[shenGongIdx],
            shenGongIdx: shenGongIdx,
            wuXingJu: juName,
            wuXingJuNum: juNum,
            mingZhu: mingZhu,
            shenZhu: shenZhu,
            lunarDate: lunar,
            trueSolarTime: trueSolarTimeStr,
            clockTime: clockTimeStr,
            flowYearGanZhi: flowYearGanZhi,
            liuDou: liuDou,
            laiYinGong: laiYinGong,
            lunarMonthCount: lunarMonthCount,
            layer2Gong: nil,
            layer3Gong: nil,
            nominalAge: nominalAge,
            siHuaInfo: siHua,
            isMale: isMale,
            isShun: isShun,
            timeInputMode: timeInputMode,
            useMonthAdjustment: useMonthAdjustment
        )
    }
}
