import Foundation
@testable import ZiWeiDoushuDianLiangXingKong

enum APKBaselineInputError: Error, Equatable {
    case invalidApkRaw(String)
}

/// 单条 APK 基线 fixture（对应 `Fixtures/APKBaselines/{id}.json`）。
struct APKBaselineCase: Codable, Equatable {
    let id: String
    let input: Input
    let expected: Expected
    let source: Source

    struct Input: Codable, Equatable {
        /// 原始 APK 参数串；允许保留 `#` 前的任意前缀。
        let apkRaw: String

        func makeChart() throws -> ZiWeiChart {
            guard let chartInput = ChartInput.fromApkString(apkRaw) else {
                throw APKBaselineInputError.invalidApkRaw(apkRaw)
            }

            return ZiWeiEngine.generateChart(
                year: chartInput.year,
                month: chartInput.month,
                day: chartInput.day,
                hour: chartInput.hour,
                minute: chartInput.minute,
                isMale: chartInput.isMale,
                timeInputMode: chartInput.timeInputMode,
                isLeapMonth: chartInput.isLeapMonth,
                useMonthAdjustment: chartInput.useMonthAdjustment,
                longitude: chartInput.longitude
            )
        }
    }

    struct Expected: Codable, Equatable {
        let global: Global
        let palaces: [PalaceExpectation]
    }

    struct Global: Codable, Equatable {
        let mingGong: String?
        let shenGong: String?
        let mingZhu: String?
        let shenZhu: String?
        let isShun: Bool?
        let siHuaInfo: [String]?
    }

    /// 宫位级契约允许按需只校验少量已确认字段。
    struct PalaceExpectation: Codable, Equatable {
        let position: String
        let daXian: String?
        let majorStarNames: [String]?
    }

    struct Source: Codable, Equatable {
        let apkClockRaw: String?
        let documents: [String]
        let notes: [String]
    }
}
