import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

final class ZiWeiChartComparableSnapshotTests: XCTestCase {
    func testSnapshotCapturesCoreRegressionFields() {
        let chart = ZiWeiEngine.generateChart(
            year: 1990,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            isMale: true,
            timeInputMode: .clockTime,
            isLeapMonth: false,
            useMonthAdjustment: false,
            longitude: 120.0
        )

        let snapshot = ZiWeiChartComparableSnapshot(chart: chart)

        XCTAssertEqual(snapshot.global.mingGong, chart.mingGong)
        XCTAssertEqual(snapshot.global.shenGong, chart.shenGong)
        XCTAssertEqual(snapshot.global.isShun, chart.isShun)
        XCTAssertEqual(snapshot.global.siHuaInfo.count, chart.siHuaInfo.count)
        XCTAssertEqual(snapshot.palaces.count, 12)
        XCTAssertEqual(snapshot.palace(at: chart.mingGong)?.name, "命宫")
    }

    func testSnapshotKeepsSiHuaInfoInRegressionOrder() throws {
        let fixture = try APKBaselineLoader.load(id: "sihua-smoke")
        let snapshot = ZiWeiChartComparableSnapshot(chart: try fixture.input.makeChart())

        XCTAssertEqual(snapshot.global.siHuaInfo, fixture.expected.global.siHuaInfo)
    }

    func testSnapshotExposesMajorStarsAsStableNameArrays() throws {
        let fixture = try APKBaselineLoader.load(id: "star-placement-smoke")
        let snapshot = ZiWeiChartComparableSnapshot(chart: try fixture.input.makeChart())

        for palaceExpectation in fixture.expected.palaces {
            let palace = try XCTUnwrap(snapshot.palace(at: palaceExpectation.position))
            let majorStarNames = palace.majorStars.map(\.name)

            XCTAssertFalse(majorStarNames.isEmpty, "宫位 \(palaceExpectation.position) 应暴露正曜数组")
            XCTAssertEqual(majorStarNames, majorStarNames.sorted())
        }
    }

    func testStarPlacementSmokeMatchesAdditionalAPKObservedPalaces() throws {
        let fixture = try APKBaselineLoader.load(id: "star-placement-smoke")
        let snapshot = ZiWeiChartComparableSnapshot(chart: try fixture.input.makeChart())

        let extraObservedPalaces: [String: [String]] = [
            "子": ["巨门"],
            "丑": ["天相"],
            "巳": ["太阳"],
            "未": ["破军", "紫微"],
            "申": ["天府"],
            "酉": ["太阴"]
        ]

        for (position, expectedNames) in extraObservedPalaces {
            let palace = try XCTUnwrap(snapshot.palace(at: position), "缺少宫位 \(position)")
            XCTAssertEqual(
                palace.majorStars.map(\.name),
                expectedNames,
                "star-placement-smoke 的 \(position) 宫主星仍未与 APK 盘面截图对齐"
            )
        }
    }
}
