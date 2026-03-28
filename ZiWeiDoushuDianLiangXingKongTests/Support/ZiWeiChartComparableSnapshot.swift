import Foundation
@testable import ZiWeiDoushuDianLiangXingKong

struct ZiWeiChartComparableSnapshot: Equatable {
    // 当前快照只覆盖第一波 APK 回归目标：命身宫、四化、大限/流年相关字段和宫位星曜分布。
    struct Global: Equatable {
        let mingGong: String
        let shenGong: String
        let wuXingJu: String
        let mingZhu: String
        let shenZhu: String
        let laiYinGong: String
        let flowYearGanZhi: String
        let liuDou: String
        let nominalAge: Int
        let isShun: Bool
        let siHuaInfo: [String]
    }

    struct StarSnapshot: Equatable {
        let name: String
        let brightness: String?
        let siHua: String?
    }

    struct TransformSnapshot: Equatable {
        let star: String
        let hua: String
        let targetPosition: String
        let targetPalace: String
        let strength: Int
    }

    struct PalaceSnapshot: Equatable {
        let name: String
        let position: String
        let tianGan: String
        let daXian: String
        let xiaoXian: String
        let changSheng: String
        let suiQian: String
        let jiangQian: String
        let boshi: String
        let majorStars: [StarSnapshot]
        let supportingStars: [StarSnapshot]
        let shaStars: [StarSnapshot]
        let miscStars: [StarSnapshot]
        let flowYearStars: [StarSnapshot]
        let gongTransforms: [TransformSnapshot]
        let chongHua: [TransformSnapshot]
        let ziHua: [TransformSnapshot]
    }

    let global: Global
    let palaces: [PalaceSnapshot]

    init(chart: ZiWeiChart) {
        global = Global(
            mingGong: chart.mingGong,
            shenGong: chart.shenGong,
            wuXingJu: chart.wuXingJu,
            mingZhu: chart.mingZhu,
            shenZhu: chart.shenZhu,
            laiYinGong: chart.laiYinGong,
            flowYearGanZhi: chart.flowYearGanZhi,
            liuDou: chart.liuDou,
            nominalAge: chart.nominalAge,
            isShun: chart.isShun,
            siHuaInfo: chart.siHuaInfo
                .map { "\($0.key):\($0.value)" }
                .sorted(by: Self.compareSiHuaEntry)
        )

        // 用固定地支顺序归一化宫位，避免回归测试受渲染顺序影响。
        palaces = chart.palaces
            .map(Self.makePalaceSnapshot)
            .sorted { Self.positionOrder($0.position) < Self.positionOrder($1.position) }
    }

    func palace(at position: String) -> PalaceSnapshot? {
        palaces.first(where: { $0.position == position })
    }

    private static func makePalaceSnapshot(from palace: Palace) -> PalaceSnapshot {
        let grouped = Dictionary(grouping: palace.stars, by: \.category)
        return PalaceSnapshot(
            name: palace.name,
            position: palace.position,
            tianGan: palace.tianGan,
            daXian: palace.daXian,
            xiaoXian: palace.xiaoXian,
            changSheng: palace.changSheng,
            suiQian: palace.suiQian,
            jiangQian: palace.jiangQian,
            boshi: palace.boshi,
            majorStars: makeStarSnapshots(grouped[.zhengYao] ?? []),
            supportingStars: makeStarSnapshots(grouped[.fuXing] ?? []),
            shaStars: makeStarSnapshots(grouped[.shaXing] ?? []),
            miscStars: makeStarSnapshots(grouped[.zaYao] ?? []),
            flowYearStars: makeStarSnapshots(grouped[.liuNian] ?? []),
            gongTransforms: makeTransformSnapshots(palace.gongTransforms),
            chongHua: makeTransformSnapshots(palace.chongHua),
            ziHua: makeTransformSnapshots(palace.ziHua)
        )
    }

    private static func makeStarSnapshots(_ stars: [Star]) -> [StarSnapshot] {
        stars
            .map { StarSnapshot(name: $0.name, brightness: $0.brightness, siHua: $0.siHua) }
            .sorted {
                if $0.name != $1.name { return $0.name < $1.name }
                if $0.brightness != $1.brightness { return ($0.brightness ?? "") < ($1.brightness ?? "") }
                return ($0.siHua ?? "") < ($1.siHua ?? "")
            }
    }

    private static func makeTransformSnapshots(_ transforms: [PalaceTransform]) -> [TransformSnapshot] {
        transforms
            .map {
                TransformSnapshot(
                    star: $0.star,
                    hua: $0.hua,
                    targetPosition: $0.targetPosition,
                    targetPalace: $0.targetPalace,
                    strength: $0.strength
                )
            }
            .sorted(by: compareTransform)
    }

    private static func compareTransform(_ lhs: TransformSnapshot, _ rhs: TransformSnapshot) -> Bool {
        let lhsOrder = huaOrder(lhs.hua)
        let rhsOrder = huaOrder(rhs.hua)
        if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
        if lhs.star != rhs.star { return lhs.star < rhs.star }
        if lhs.targetPosition != rhs.targetPosition { return lhs.targetPosition < rhs.targetPosition }
        if lhs.targetPalace != rhs.targetPalace { return lhs.targetPalace < rhs.targetPalace }
        return lhs.strength < rhs.strength
    }

    private static func compareSiHuaEntry(_ lhs: String, _ rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ":", maxSplits: 1).map(String.init)
        let rhsParts = rhs.split(separator: ":", maxSplits: 1).map(String.init)
        let lhsOrder = huaOrder(lhsParts.count > 1 ? lhsParts[1] : "")
        let rhsOrder = huaOrder(rhsParts.count > 1 ? rhsParts[1] : "")
        if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
        return lhs < rhs
    }

    private static func huaOrder(_ hua: String) -> Int {
        switch hua {
        case "化禄": return 0
        case "化权": return 1
        case "化科": return 2
        case "化忌": return 3
        default: return 99
        }
    }

    private static func positionOrder(_ position: String) -> Int {
        earthlyBranches.firstIndex(of: position) ?? Int.max
    }

    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
}
