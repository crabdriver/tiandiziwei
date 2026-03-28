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

    func testLoadDaxianDirectionSmokeFixture() throws {
        let fixture = try APKBaselineLoader.load(id: "daxian-direction-smoke")

        XCTAssertEqual(fixture.id, "daxian-direction-smoke")
        XCTAssertEqual(fixture.expected.global.isShun, true)
        XCTAssertEqual(fixture.expected.palaces.count, 12)
        XCTAssertEqual(fixture.expected.palaces.first(where: { $0.position == "辰" })?.daXian, "2~11")
        XCTAssertEqual(fixture.expected.palaces.first(where: { $0.position == "亥" })?.daXian, "72~81")
    }

    func testLoadSiHuaSmokeFixture() throws {
        let fixture = try APKBaselineLoader.load(id: "sihua-smoke")

        XCTAssertEqual(fixture.id, "sihua-smoke")
        XCTAssertFalse(try XCTUnwrap(fixture.expected.global.siHuaInfo).isEmpty)
    }

    func testLoadStarPlacementSmokeFixture() throws {
        let fixture = try APKBaselineLoader.load(id: "star-placement-smoke")

        XCTAssertEqual(fixture.id, "star-placement-smoke")
        XCTAssertFalse(fixture.expected.palaces.isEmpty)
        XCTAssertNotNil(fixture.expected.palaces.first?.majorStarNames)
    }

    func testLoadAllIncludesCoreFieldsSmoke() throws {
        let fixtures = try APKBaselineLoader.loadAll()

        XCTAssertTrue(fixtures.contains(where: { $0.id == "core-fields-smoke" }))
        XCTAssertTrue(fixtures.contains(where: { $0.id == "daxian-direction-smoke" }))
        XCTAssertTrue(fixtures.contains(where: { $0.id == "sihua-smoke" }))
        XCTAssertTrue(fixtures.contains(where: { $0.id == "star-placement-smoke" }))
    }

    func testFixtureInputMakeChartParsesRealApkString() throws {
        let fixture = try APKBaselineLoader.load(id: "core-fields-smoke")
        let chart = try fixture.input.makeChart()

        XCTAssertEqual(chart.mingGong, "辰")
        XCTAssertEqual(chart.shenGong, "寅")
    }

    func testDaxianFixtureInputMakeChartMatchesVisibleAgeRanges() throws {
        let fixture = try APKBaselineLoader.load(id: "daxian-direction-smoke")
        let chart = try fixture.input.makeChart()
        let chenExpectation = try XCTUnwrap(
            fixture.expected.palaces.first(where: { $0.position == "辰" })
        )
        let haiExpectation = try XCTUnwrap(
            fixture.expected.palaces.first(where: { $0.position == "亥" })
        )

        XCTAssertEqual(chart.isShun, fixture.expected.global.isShun)
        XCTAssertEqual(chart.palaces.first(where: { $0.position == "辰" })?.daXian, chenExpectation.daXian)
        XCTAssertEqual(chart.palaces.first(where: { $0.position == "亥" })?.daXian, haiExpectation.daXian)
    }
}
