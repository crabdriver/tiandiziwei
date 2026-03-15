// FlowYearStars.swift - 流年星系 + 小限计算
// 紫微斗数-点亮星空版 iOS 版
// 对应 Android 版 zwpview.java 中的流年星安排逻辑

import Foundation

/// 流年/大限辅助计算
struct FlowYearStars {
    
    // MARK: - 岁建十二星
    // 从 zwpview.java 第 1224 行提取
    static let suiJianNames = ["岁建", "晦气", "丧门", "贯索", "官符", "小耗", "大耗", "龙德", "白虎", "天德", "吊客", "病符"]
    
    /// 安岁建十二星: 从流年地支顺行
    static func placeSuiJian(yearZhiIdx: Int) -> [Int: String] {
        var result: [Int: String] = [:]
        for i in 0..<12 {
            result[(yearZhiIdx + i) % 12] = suiJianNames[i]
        }
        return result
    }
    
    // MARK: - 将前十二星
    // 从 zwpview.java 第 1225 行提取
    static let jiangQianNames = ["将星", "攀鞍", "岁驿", "息神", "华盖", "劫煞", "灾煞", "天煞", "指背", "咸池", "月煞", "亡神"]
    
    /// 安将前十二星: 从将星位置顺行
    /// 将星位置由年支决定: 寅午戌→午, 申子辰→子, 巳酉丑→酉, 亥卯未→卯
    static func placeJiangQian(yearZhiIdx: Int) -> [Int: String] {
        let jiangXingPos: Int
        switch yearZhiIdx {
        case 2, 6, 10:  // 寅午戌
            jiangXingPos = 6  // 午
        case 8, 0, 4:   // 申子辰
            jiangXingPos = 0  // 子
        case 5, 9, 1:   // 巳酉丑
            jiangXingPos = 9  // 酉
        case 11, 3, 7:  // 亥卯未
            jiangXingPos = 3  // 卯
        default:
            jiangXingPos = 0
        }
        
        var result: [Int: String] = [:]
        for i in 0..<12 {
            result[(jiangXingPos + i) % 12] = jiangQianNames[i]
        }
        return result
    }
    
    // MARK: - 博士十二星
    // 从 zwpview.java 第 1226 行提取
    static let boshiNames = ["博士", "力士", "青龙", "小耗", "将军", "奏书", "飞廉", "喜神", "病符", "大耗", "伏兵", "官府"]
    
    /// 安博士十二星: 从禄存位置起，阳男阴女顺行，阴男阳女逆行
    static func placeBoshi(luCunPos: Int, isShun: Bool) -> [Int: String] {
        var result: [Int: String] = [:]
        for i in 0..<12 {
            let pos = isShun ? (luCunPos + i) % 12 : (luCunPos - i + 12) % 12
            result[pos] = boshiNames[i]
        }
        return result
    }
    
    // MARK: - 小限计算
    
    /// 计算小限位置
    /// 小限: 男命从寅宫起1岁顺行，女命从申宫起1岁逆行
    /// 更精确: 根据年支确定起始宫位
    static func xiaoXianPosition(currentAge: Int, isMale: Bool, yearZhiIdx: Int) -> Int {
        // 小限起始位置根据出生年地支和性别确定
        // 子午卯酉年生: 男起辰(4), 女起戌(10)
        // 寅申巳亥年生: 男起寅(2), 女起申(8)
        // 辰戌丑未年生: 男起子(0), 女起午(6)
        
        let startPos: Int
        switch yearZhiIdx {
        case 0, 3, 6, 9:  // 子卯午酉
            startPos = isMale ? 4 : 10
        case 2, 5, 8, 11: // 寅巳申亥
            startPos = isMale ? 2 : 8
        case 1, 4, 7, 10: // 丑辰未戌
            startPos = isMale ? 0 : 6
        default:
            startPos = 0
        }
        
        let offset = (currentAge - 1) % 12
        if isMale {
            return (startPos + offset) % 12
        } else {
            return (startPos - offset + 12) % 12
        }
    }
    
    /// 计算某岁的小限宫位名称
    static func xiaoXianZhi(currentAge: Int, isMale: Bool, yearZhiIdx: Int) -> String {
        let pos = xiaoXianPosition(currentAge: currentAge, isMale: isMale, yearZhiIdx: yearZhiIdx)
        return diZhi[pos]
    }
    
    // MARK: - 流年四化
    
    /// 计算流年四化
    static func liuNianSiHua(flowYearGan: String) -> [String: String] {
        // 与紫微斗数引擎四化表相同
        return ZiWeiEngine.calculateSiHua(yearGan: flowYearGan)
    }
    
    // MARK: - 流年命宫
    
    /// 确定流年命宫: 斗君起太岁，斗君 = 从命宫起正月逆数到出生月，再从该宫起子时顺数到出生时
    static func liuNianMingGong(mingGongIdx: Int, birthMonth: Int, birthHourIdx: Int, flowYearZhiIdx: Int) -> Int {
        // 斗君推算
        // 1. 从命宫起正月(逆行)
        let douJunMonth = (mingGongIdx - (birthMonth - 1) + 12) % 12
        // 2. 从该宫起子时(顺行)
        let douJun = (douJunMonth + birthHourIdx) % 12
        // 3. 流年命宫 = 从斗君起流年地支
        let liuNianMing = (douJun + flowYearZhiIdx) % 12
        return liuNianMing
    }
    
    // MARK: - 大限四化
    
    /// 计算当前年龄对应的大限宫位
    static func currentDaXian(age: Int, juNum: Int, isShun: Bool) -> (gongIdx: Int, startAge: Int, endAge: Int)? {
        for i in 0..<12 {
            let start: Int
            let gongIdx: Int
            if isShun {
                start = juNum + i * 10
                gongIdx = i
            } else {
                start = juNum + i * 10
                gongIdx = 11 - i
            }
            let end = start + 9
            if age >= start && age <= end {
                return (gongIdx: gongIdx, startAge: start, endAge: end)
            }
        }
        return nil
    }
    
    // MARK: - 流年干支计算
    
    /// 根据公历年计算流年天干地支
    static func flowYearGanZhi(year: Int) -> (gan: String, zhi: String, ganIdx: Int, zhiIdx: Int) {
        let offset = year - 4
        let ganIdx = ((offset % 10) + 10) % 10
        let zhiIdx = ((offset % 12) + 12) % 12
        return (tianGan[ganIdx], diZhi[zhiIdx], ganIdx, zhiIdx)
    }
}
