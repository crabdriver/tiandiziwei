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

            assertEqualIfPresent(
                snapshot.global.isShun,
                fixture.expected.global.isShun,
                fixtureID: fixture.id,
                field: "isShun"
            )
            assertEqualIfPresent(
                snapshot.global.siHuaInfo,
                fixture.expected.global.siHuaInfo,
                fixtureID: fixture.id,
                field: "siHuaInfo"
            )

            for palaceExpectation in fixture.expected.palaces {
                let palace = try XCTUnwrap(
                    snapshot.palace(at: palaceExpectation.position),
                    "[\(fixture.id)] 缺少宫位 \(palaceExpectation.position)"
                )

                assertEqualIfPresent(
                    palace.daXian,
                    palaceExpectation.daXian,
                    fixtureID: fixture.id,
                    field: "palaces[\(palaceExpectation.position)].daXian"
                )
                assertEqualIfPresent(
                    palace.majorStars.map(\.name),
                    palaceExpectation.majorStarNames,
                    fixtureID: fixture.id,
                    field: "palaces[\(palaceExpectation.position)].majorStarNames"
                )
            }
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

    private func assertEqualIfPresent(
        _ actual: Bool,
        _ expected: Bool?,
        fixtureID: String,
        field: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "[\(fixtureID)] \(field) mismatch", file: file, line: line)
    }

    private func assertEqualIfPresent(
        _ actual: [String],
        _ expected: [String]?,
        fixtureID: String,
        field: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "[\(fixtureID)] \(field) mismatch", file: file, line: line)
    }
}
