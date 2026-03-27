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
    }

    /// 宫位级契约占位；当前 smoke fixture 可为空数组。
    struct PalaceExpectation: Codable, Equatable {}

    struct Source: Codable, Equatable {
        let apkClockRaw: String?
        let documents: [String]
        let notes: [String]
    }
}
