import XCTest
@testable import ZiWeiDoushuDianLiangXingKong

/// 农历/时辰索引等纯函数（不触发完整排盘）
final class LunarCalendarConverterTests: XCTestCase {
    // MARK: - hourToShiChen（传统：23 点入子时）

    func testHourToShiChen_SubHourBoundary() {
        XCTAssertEqual(LunarCalendarConverter.hourToShiChen(23), 0) // 子时
        XCTAssertEqual(LunarCalendarConverter.hourToShiChen(0), 0)
        XCTAssertEqual(LunarCalendarConverter.hourToShiChen(1), 0)
        XCTAssertEqual(LunarCalendarConverter.hourToShiChen(2), 1) // 丑时
        XCTAssertEqual(LunarCalendarConverter.hourToShiChen(22), 11) // 亥时
    }

    // MARK: - hourToShiChenClockTime（钟表：00 点入子时）

    func testHourToShiChenClockTime() {
        XCTAssertEqual(LunarCalendarConverter.hourToShiChenClockTime(0), 0)
        XCTAssertEqual(LunarCalendarConverter.hourToShiChenClockTime(1), 0)
        XCTAssertEqual(LunarCalendarConverter.hourToShiChenClockTime(2), 1)
        XCTAssertEqual(LunarCalendarConverter.hourToShiChenClockTime(23), 11)
    }

    // MARK: - 阴历数据表（闰月、月天数）

    func testLeapMonthIsNibbleOfDataTable() {
        let m = LunarCalendarConverter.leapMonth(2020)
        XCTAssertTrue((0...12).contains(m))
    }

    func testMonthDaysSmallMonth() {
        let days = LunarCalendarConverter.monthDays(2020, 1)
        XCTAssertTrue(days == 29 || days == 30)
    }

    func testLunarYearDaysReasonableRange() {
        let y2020 = LunarCalendarConverter.lunarYearDays(2020)
        XCTAssertGreaterThanOrEqual(y2020, 350)
        XCTAssertLessThanOrEqual(y2020, 390)
    }
}
