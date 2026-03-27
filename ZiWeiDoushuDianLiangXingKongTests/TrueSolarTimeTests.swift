import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

/// 真太阳时与均时差：纯数值路径，不调用排盘引擎
final class TrueSolarTimeTests: XCTestCase {
    func testEquationOfTimeDeterministic() {
        let a = TrueSolarTime.equationOfTime(year: 2000, month: 6, day: 15)
        let b = TrueSolarTime.equationOfTime(year: 2000, month: 6, day: 15)
        XCTAssertEqual(a, b, accuracy: 1e-9)
    }

    /// 东经 120° 与标准经度一致时，经度修正为 0，结果仅受均时差影响
    func testCalculateAtStandardMeridianLongitudeCorrectionZero() {
        let r = TrueSolarTime.calculate(
            year: 2000, month: 6, day: 15,
            hour: 12, minute: 0,
            longitude: 120.0,
            standardMeridian: 120.0
        )
        XCTAssertEqual(r.dayOffset, 0)
        // 与均时差一致：总分钟 = 12*60 + eot
        let eot = TrueSolarTime.equationOfTime(year: 2000, month: 6, day: 15)
        let expectedTotal = 12 * 60 + eot
        let rounded = Int(round(expectedTotal))
        XCTAssertEqual(r.hour, rounded / 60)
        XCTAssertEqual(r.minute, rounded % 60)
    }

    func testConvertLongitude120ReturnsStableTrueSolarComponents() {
        let result = TrueSolarTime.convert(
            year: 1990, month: 5, day: 15,
            hour: 10, minute: 30,
            longitude: 120.0
        )
        XCTAssertEqual(result.trueSolarYear, 1990)
        XCTAssertEqual(result.trueSolarMonth, 5)
        XCTAssertEqual(result.trueSolarDay, 15)
        XCTAssertGreaterThanOrEqual(result.trueSolarHour, 0)
        XCTAssertLessThan(result.trueSolarHour, 24)
        XCTAssertGreaterThanOrEqual(result.trueSolarMinute, 0)
        XCTAssertLessThan(result.trueSolarMinute, 60)
    }
}
