import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

final class APKBaselineRegressionTests: XCTestCase {
    func testConfirmedGlobalFieldsMatchAPKBaselines() throws {
        let fixtures = try APKBaselineLoader.loadAll()

        XCTAssertFalse(fixtures.isEmpty, "至少应存在一个真实 APK 基线样本。")

        for fixture in fixtures {
            let chart = try fixture.input.makeChart()
            let snapshot = ZiWeiChartComparableSnapshot(chart: chart)

            assertEqualIfPresent(
                snapshot.global.mingGong,
                fixture.expected.global.mingGong,
                fixtureID: fixture.id,
                field: "mingGong"
            )
            assertEqualIfPresent(
                snapshot.global.shenGong,
                fixture.expected.global.shenGong,
                fixtureID: fixture.id,
                field: "shenGong"
            )
            assertEqualIfPresent(
                snapshot.global.mingZhu,
                fixture.expected.global.mingZhu,
                fixtureID: fixture.id,
                field: "mingZhu"
            )
            assertEqualIfPresent(
                snapshot.global.shenZhu,
                fixture.expected.global.shenZhu,
                fixtureID: fixture.id,
                field: "shenZhu"
            )
        }
    }

    private func assertEqualIfPresent(
        _ actual: String,
        _ expected: String?,
        fixtureID: String,
        field: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "[\(fixtureID)] \(field) mismatch", file: file, line: line)
    }
}
