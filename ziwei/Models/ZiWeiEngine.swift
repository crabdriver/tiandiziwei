// ZiWeiEngine.swift - 紫微斗数排盘核心引擎
// 紫微星语 iOS 版

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
    var siHuaInfo: [String: String]  // 四化信息
    var isMale: Bool                 // 性别
    var isShun: Bool                 // 大限是否顺行
}

// MARK: - 紫微斗数排盘引擎

class ZiWeiEngine {
    
    // MARK: - 常量定义
    
    /// 十四正曜
    static let zhengYao14 = [
        "紫微", "天机", "太阳", "武曲", "天同", "廉贞",
        "天府", "太阴", "贪狼", "巨门", "天相", "天梁", "七杀", "破军"
    ]
    
    /// 十二宫名称（固定顺序，按逆时针排列）
    static let gongNames = [
        "命宫", "兄弟宫", "夫妻宫", "子女宫", "财帛宫", "疾厄宫",
        "迁移宫", "交友宫", "事业宫", "田宅宫", "福德宫", "父母宫"
    ]
    
    /// 五行局对照表 (纳音五行 -> 局数)
    /// 行号=天干(年干)索引, 列号=地支(命宫地支)索引
    /// 水二局=2, 木三局=3, 金四局=4, 土五局=5, 火六局=6
    static let wuXingJuTable: [[Int]] = [
        // 子  丑  寅  卯  辰  巳  午  未  申  酉  戌  亥
        [  2,  6,  3,  5,  4,  2,  6,  3,  5,  4,  2,  6], // 甲/己
        [  6,  5,  2,  4,  3,  6,  5,  2,  4,  3,  6,  5], // 乙/庚
        [  5,  4,  6,  3,  2,  5,  4,  6,  3,  2,  5,  4], // 丙/辛
        [  4,  3,  5,  2,  6,  4,  3,  5,  2,  6,  4,  3], // 丁/壬
        [  3,  2,  4,  6,  5,  3,  2,  4,  6,  5,  3,  2], // 戊/癸
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
        "辰": "文昌", "巳": "天机", "午": "火星", "未": "天相",
        "申": "天梁", "酉": "天同", "戌": "文昌", "亥": "天机"
    ]
    
    /// 紫微星安星表 - 根据五行局数和农历日安紫微星
    /// 返回紫微星所在的地支索引(0=子, 1=丑, ...)
    static func locateZiWei(juNum: Int, day: Int) -> Int {
        // 紫微星安星规则：五行局数起始排列
        // 日数除以局数，用商和余数来确定紫微星位置
        let quotient: Int
        let remainder = day % juNum
        
        if remainder == 0 {
            quotient = day / juNum
        } else {
            quotient = day / juNum + 1
        }
        
        // 根据余数调整商数
        // 余数为0时，紫微星的初始位置从寅宫
        // 具体算法：
        // 起始位置 = 寅(索引2)
        // 商数 - 1 即为从寅向前数的宫数
        
        var position = 2 + quotient - 1 // 寅宫(2) + 偏移
        
        // 余数校正
        if remainder != 0 {
            // 余数为偶数时逆行，奇数时顺行
            if remainder % 2 == 0 {
                position = position - remainder
            } else {
                position = position + remainder
            }
        }
        
        return ((position % 12) + 12) % 12
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
    
    /// 安辅星
    static func placeAuxiliaryStars(lunar: LunarDate) -> [String: Int] {
        var result: [String: Int] = [:]
        let monthIdx = lunar.month - 1
        let hourIdx = lunar.hourZhiIndex
        let yearZhiIdx = diZhi.firstIndex(of: lunar.yearZhi)!
        
        // 左辅: 从辰宫起正月，顺行
        result["左辅"] = (4 + monthIdx) % 12
        // 右弼: 从戌宫起正月，逆行
        result["右弼"] = (10 - monthIdx + 12) % 12
        
        // 文昌: 从戌宫起子时，逆行
        result["文昌"] = (10 - hourIdx + 12) % 12
        // 文曲: 从辰宫起子时，顺行
        result["文曲"] = (4 + hourIdx) % 12
        
        // 禄存: 根据年干
        let yearGanIdx = tianGan.firstIndex(of: lunar.yearGan)!
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
        let tianKuiPos = [1, 0, 11, 11, 1, 0, 7, 6, 3, 3] // 甲丑乙子...
        let tianYuePos = [7, 8, 9, 9, 7, 8, 1, 2, 5, 5]
        result["天魁"] = tianKuiPos[yearGanIdx]
        result["天钺"] = tianYuePos[yearGanIdx]
        
        return result
    }
    
    /// 安杂曜
    static func placeMiscStars(lunar: LunarDate) -> [String: Int] {
        var result: [String: Int] = [:]
        let yearZhiIdx = diZhi.firstIndex(of: lunar.yearZhi)!
        let monthIdx = lunar.month - 1
        let dayIdx = lunar.day - 1
        let hourIdx = lunar.hourZhiIndex
        
        // 天马: 根据年支
        let tianMaPos = [2, 11, 8, 5, 2, 11, 8, 5, 2, 11, 8, 5]
        result["天马"] = tianMaPos[yearZhiIdx]
        
        // 红鸾: 从卯宫起子年逆行
        result["红鸾"] = (3 - yearZhiIdx + 12) % 12
        // 天喜: 红鸾对宫
        result["天喜"] = (result["红鸾"]! + 6) % 12
        
        // 天哭: 从午宫起子年顺行
        result["天哭"] = (6 + yearZhiIdx) % 12
        // 天虚: 从午宫起子年逆行
        result["天虚"] = (6 - yearZhiIdx + 12) % 12
        
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
        let guaSuPos = [10, 10, 1, 1, 1, 4, 4, 4, 7, 7, 7, 10]
        result["寡宿"] = guaSuPos[yearZhiIdx]
        
        // 天才: 从命宫起年支顺数到生月再顺数到生时
        // 天寿: 从身宫起年支...（简化处理）
        
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
    
    /// 安十二宫（从命宫开始逆时针排列）
    static func arrangePalaces(mingGongIdx: Int) -> [(name: String, zhiIdx: Int)] {
        var result: [(name: String, zhiIdx: Int)] = []
        for i in 0..<12 {
            let zhiIdx = (mingGongIdx - i + 12) % 12
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
    
    /// 计算大限（根据五行局数和阴阳）
    static func calculateDaXian(juNum: Int, isMale: Bool, yearGanIdx: Int) -> [(start: Int, end: Int)] {
        // 阳男阴女顺行，阴男阳女逆行
        let isYangGan = yearGanIdx % 2 == 0
        let isShun = (isMale && isYangGan) || (!isMale && !isYangGan)
        
        var result: [(start: Int, end: Int)] = []
        for i in 0..<12 {
            let start = juNum + i * 10
            let end = start + 9
            result.append((start: start, end: end))
        }
        
        if !isShun {
            result.reverse()
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
    
    // MARK: - 主排盘方法
    
    /// 执行完整的紫微排盘
    static func generateChart(
        year: Int, month: Int, day: Int, hour: Int, minute: Int,
        isMale: Bool, longitude: Double = 120.0, timeZone: Int = 8
    ) -> ZiWeiChart {
        
        // 0. 真太阳时修正
        let solarTimeResult = TrueSolarTime.convert(
            year: year, month: month, day: day,
            hour: hour, minute: minute, longitude: longitude
        )
        let trueHour = solarTimeResult.trueSolarHour
        let trueMinute = solarTimeResult.trueSolarMinute
        
        // 1. 公历转阴历
        var lunar = LunarCalendarConverter.solarToLunar(year: year, month: month, day: day)
        let hourIdx = LunarCalendarConverter.hourToShiChen(trueHour)
        lunar.hourZhiIndex = hourIdx
        lunar.hourZhi = diZhi[hourIdx]
        
        // 重新计算时干
        let dayGanIdx = tianGan.firstIndex(of: lunar.dayGan)!
        let hGanStart = (dayGanIdx % 5) * 2
        let hGanIdx = (hGanStart + hourIdx) % 10
        lunar.hourGan = tianGan[hGanIdx]
        lunar.hourGanZhi = lunar.hourGan + lunar.hourZhi
        
        // 2. 确定命宫和身宫
        let mingGongIdx = locateMingGong(month: lunar.month, hourIdx: hourIdx)
        let shenGongIdx = locateShenGong(month: lunar.month, hourIdx: hourIdx)
        
        // 3. 确定五行局
        let yearGanIdx = tianGan.firstIndex(of: lunar.yearGan)!
        let juNum = wuXingJuTable[yearGanIdx % 5][mingGongIdx]
        let juName = wuXingJuName[juNum]!
        
        // 4. 安十二宫
        let palaceArrangement = arrangePalaces(mingGongIdx: mingGongIdx)
        
        // 5. 安紫微星
        let ziWeiPos = locateZiWei(juNum: juNum, day: lunar.day)
        let ziWeiSeries = placeZiWeiSeries(ziWeiPos: ziWeiPos)
        let tianFuSeries = placeTianFuSeries(ziWeiPos: ziWeiPos)
        
        // 6. 安辅星
        let auxStars = placeAuxiliaryStars(lunar: lunar)
        
        // 7. 安杂曜
        let miscStars = placeMiscStars(lunar: lunar)
        
        // 8. 计算四化
        let siHua = calculateSiHua(yearGan: lunar.yearGan)
        
        // 9. 大限方向
        let isYangGan = yearGanIdx % 2 == 0
        let isShun = (isMale && isYangGan) || (!isMale && !isYangGan)
        
        // 10. 计算大限
        let daXianList = calculateDaXian(juNum: juNum, isMale: isMale, yearGanIdx: yearGanIdx)
        
        // 11. 长生十二宫
        let changShengMap = calculateChangSheng(juNum: juNum, isShun: isShun)
        
        // 12. 流年星系
        let yearZhiIdx = diZhi.firstIndex(of: lunar.yearZhi)!
        let suiJianMap = FlowYearStars.placeSuiJian(yearZhiIdx: yearZhiIdx)
        let jiangQianMap = FlowYearStars.placeJiangQian(yearZhiIdx: yearZhiIdx)
        let luCunPos = auxStars["禄存"] ?? 0
        let boshiMap = FlowYearStars.placeBoshi(luCunPos: luCunPos, isShun: isShun)
        
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
                    starsInPalace.append(Star(name: starName, category: .zaYao))
                }
            }
            
            let daXian = idx < daXianList.count ? "\(daXianList[idx].start)~\(daXianList[idx].end)" : ""
            
            // 长生
            let changSheng = changShengMap[arrangement.zhiIdx] ?? ""
            
            // 流年星
            let suiQian = suiJianMap[arrangement.zhiIdx] ?? ""
            let jiangQian = jiangQianMap[arrangement.zhiIdx] ?? ""
            let boshi = boshiMap[arrangement.zhiIdx] ?? ""
            
            let palace = Palace(
                name: arrangement.name,
                position: zhi,
                tianGan: gongGan,
                stars: starsInPalace,
                daXian: daXian,
                xiaoXian: "",
                changSheng: changSheng,
                suiQian: suiQian,
                jiangQian: jiangQian,
                boshi: boshi
            )
            palaces.append(palace)
        }
        
        // 命主和身主
        let mingZhu = mingZhuTable[lunar.yearZhi] ?? ""
        let shenZhu = shenZhuTable[lunar.yearZhi] ?? ""
        
        // 真太阳时格式化
        let trueSolarTimeStr = String(format: "%d-%d-%d %02d:%02d", year, month, day, trueHour, trueMinute)
        let clockTimeStr = String(format: "%d-%d-%d %02d:%02d", year, month, day, hour, minute)
        
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
            siHuaInfo: siHua,
            isMale: isMale,
            isShun: isShun
        )
    }
}
