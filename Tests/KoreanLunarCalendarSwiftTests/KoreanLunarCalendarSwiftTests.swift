import XCTest
@testable import KoreanLunarCalendar

final class KoreanLunarCalendarTests: XCTestCase {
    func testInitAndFormats() {
        let cal = KoreanLunarCalendar()
        XCTAssertTrue(cal.setSolarDate(2020, 1, 1))
        XCTAssertEqual(cal.solarIsoFormat(), "2020-01-01")
        XCTAssertNil(cal.lunarIsoFormat())
        XCTAssertTrue(cal.setLunarDate(2019, 12, 6, true)) // 임시 값(윤달)
        XCTAssertNotNil(cal.lunarIsoFormat())
    }
}