import XCTest
@testable import KoreanLunarCalendar

final class KoreanLunarCalendarTests: XCTestCase {
    func testInitAndFormats() {
        let cal = KoreanLunarCalendar()
        XCTAssertTrue(cal.setSolarDate(2020, 1, 1))
        XCTAssertEqual(cal.solarIsoFormat(), "2020-01-01")
        XCTAssertNil(cal.lunarIsoFormat())
        
        // 2020년에는 윤4월이 있으므로 올바른 윤달로 테스트
        XCTAssertTrue(cal.setLunarDate(2020, 4, 15, true)) // 윤4월
        XCTAssertNotNil(cal.lunarIsoFormat())
        
        // 평달 테스트
        XCTAssertTrue(cal.setLunarDate(2019, 12, 6, false)) // 평달
        XCTAssertNotNil(cal.lunarIsoFormat())
    }
}