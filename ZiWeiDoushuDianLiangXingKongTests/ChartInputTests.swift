import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

/// 参数串解析与排盘输入一致性（工程健壮性基线）
final class ChartInputTests: XCTestCase {
    func testApkRoundTripClockTime() {
        var input = ChartInput()
        input.year = 2000
        input.month = 8
        input.day = 16
        input.hour = 14
        input.minute = 30
        input.isMale = true
        input.timeInputMode = .clockTime
        input.longitude = 120.0
        input.useMonthAdjustment = false

        let s = input.apkFullString()
        let parsed = ChartInput.fromApkString(s)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.year, 2000)
        XCTAssertEqual(parsed?.month, 8)
        XCTAssertEqual(parsed?.day, 16)
        XCTAssertEqual(parsed?.hour, 14)
        XCTAssertEqual(parsed?.minute, 30)
        XCTAssertEqual(parsed?.isMale, true)
        XCTAssertEqual(parsed?.timeInputMode, .clockTime)
        XCTAssertEqual(parsed?.longitude, 120.0)
        XCTAssertEqual(parsed?.useMonthAdjustment, false)
    }

    func testApkInvalidPayloadReturnsNil() {
        XCTAssertNil(ChartInput.fromApkString("input#1|2000"))
    }

    /// 阴历模式：12 段 payload（含闰月标志）
    func testApkRoundTripLunarWithLeapFlag() {
        var input = ChartInput()
        input.year = 2020
        input.month = 4
        input.day = 10
        input.hour = 8
        input.minute = 0
        input.isMale = false
        input.timeInputMode = .lunarTime
        input.isLeapMonth = true
        input.useMonthAdjustment = false
        input.longitude = 116.4

        let s = input.apkFullString()
        let parsed = ChartInput.fromApkString(s)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.timeInputMode, .lunarTime)
        XCTAssertEqual(parsed?.isLeapMonth, true)
        XCTAssertEqual(parsed?.year, 2020)
        XCTAssertEqual(parsed?.longitude, 116.4, accuracy: 0.01)
    }

    func testApkRoundTripTrueSolarTime() {
        var input = ChartInput()
        input.year = 1995
        input.month = 3
        input.day = 21
        input.hour = 18
        input.minute = 45
        input.isMale = true
        input.timeInputMode = .trueSolarTime
        input.longitude = 114.2
        input.useMonthAdjustment = true

        let parsed = ChartInput.fromApkString(input.apkFullString())
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.timeInputMode, .trueSolarTime)
        XCTAssertEqual(parsed?.useMonthAdjustment, true)
    }

    func testFromApkStringStripsArbitraryPrefixBeforeHash() {
        let raw = "anything#1|2000|1|1|12|0|0|120.0|-8|1|0|0"
        let parsed = ChartInput.fromApkString(raw)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.year, 2000)
        XCTAssertEqual(parsed?.timeInputMode, .clockTime)
    }
}
