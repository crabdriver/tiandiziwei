import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

final class APKBaselineLoaderTests: XCTestCase {
    func testLoadCoreFieldsSmokeFixture() throws {
        let fixture = try APKBaselineLoader.load(id: "core-fields-smoke")

        XCTAssertEqual(fixture.id, "core-fields-smoke")
        XCTAssertEqual(fixture.expected.global.mingGong, "辰")
        XCTAssertEqual(fixture.expected.global.shenGong, "寅")
        XCTAssertEqual(fixture.expected.global.mingZhu, "廉贞")
        XCTAssertEqual(fixture.expected.global.shenZhu, "铃星")
        XCTAssertEqual(fixture.expected.palaces, [])
    }

    func testLoadAllIncludesCoreFieldsSmoke() throws {
        let fixtures = try APKBaselineLoader.loadAll()

        XCTAssertTrue(fixtures.contains(where: { $0.id == "core-fields-smoke" }))
    }

    func testFixtureInputMakeChartParsesRealApkString() throws {
        let fixture = try APKBaselineLoader.load(id: "core-fields-smoke")
        let chart = try fixture.input.makeChart()

        XCTAssertEqual(chart.mingGong, "辰")
        XCTAssertEqual(chart.shenGong, "寅")
    }
}
