import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

/// 安星引擎中的表驱动与地支运算（不调用 generateChart）
final class ZiWeiEnginePureHelpersTests: XCTestCase {
    func testCalculateSiHuaJiaYear() {
        let map = ZiWeiEngine.calculateSiHua(yearGan: "甲")
        XCTAssertEqual(map["廉贞"], "化禄")
        XCTAssertEqual(map["破军"], "化权")
        XCTAssertEqual(map["武曲"], "化科")
        XCTAssertEqual(map["太阳"], "化忌")
    }

    func testCalculateSiHuaGuiYear() {
        let map = ZiWeiEngine.calculateSiHua(yearGan: "癸")
        XCTAssertEqual(map["破军"], "化禄")
        XCTAssertEqual(map["巨门"], "化权")
        XCTAssertEqual(map["太阴"], "化科")
        XCTAssertEqual(map["贪狼"], "化忌")
    }

    func testCalculateSiHuaInvalidGanReturnsEmpty() {
        XCTAssertTrue(ZiWeiEngine.calculateSiHua(yearGan: "X").isEmpty)
    }

    func testShiftZhi() {
        XCTAssertEqual(ZiWeiEngine.shiftZhi("子", steps: 1), "丑")
        XCTAssertEqual(ZiWeiEngine.shiftZhi("亥", steps: 1), "子")
        XCTAssertEqual(ZiWeiEngine.shiftZhi("子", steps: -1), "亥")
        XCTAssertEqual(ZiWeiEngine.shiftZhi("子", steps: 12), "子")
    }

    func testOppositeZhi() {
        XCTAssertEqual(ZiWeiEngine.oppositeZhi("子"), "午")
        XCTAssertEqual(ZiWeiEngine.oppositeZhi("午"), "子")
    }

    func testLocateMingGongAndShenGong() {
        // 五月、寅时 hourIdx=2：与引擎公式一致即可（不替代人工排盘验收）
        let ming = ZiWeiEngine.locateMingGong(month: 5, hourIdx: 2)
        let shen = ZiWeiEngine.locateShenGong(month: 5, hourIdx: 2)
        XCTAssertEqual(ming, 4) // 巳
        XCTAssertEqual(shen, 8) // 酉
    }

    func testAdjustedLunarMonth() {
        XCTAssertEqual(ZiWeiEngine.adjustedLunarMonth(5, useMonthAdjustment: false), 5)
        XCTAssertEqual(ZiWeiEngine.adjustedLunarMonth(12, useMonthAdjustment: true), 1)
        XCTAssertEqual(ZiWeiEngine.adjustedLunarMonth(3, useMonthAdjustment: true), 4)
    }
}
