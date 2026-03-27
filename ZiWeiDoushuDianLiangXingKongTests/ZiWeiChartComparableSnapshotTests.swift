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
}
