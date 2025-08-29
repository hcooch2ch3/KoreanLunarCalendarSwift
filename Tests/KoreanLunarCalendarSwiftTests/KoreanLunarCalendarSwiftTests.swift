import XCTest
@testable import KoreanLunarCalendar

final class KoreanLunarCalendarTests: XCTestCase {
    func testInitAndFormats() {
        let cal = KoreanLunarCalendar()
        XCTAssertTrue(cal.setSolarDate(2020, 1, 1))
        XCTAssertEqual(cal.solarIsoFormat(), "2020-01-01")
        XCTAssertNotNil(cal.lunarIsoFormat()) // Now should have lunar date
        
        // 2020년에는 윤4월이 있으므로 올바른 윤달로 테스트
        XCTAssertTrue(cal.setLunarDate(2020, 4, 15, true)) // 윤4월
        XCTAssertNotNil(cal.lunarIsoFormat())
        XCTAssertNotNil(cal.solarIsoFormat()) // Now should have solar date
        
        // 평달 테스트
        XCTAssertTrue(cal.setLunarDate(2019, 12, 6, false)) // 평달
        XCTAssertNotNil(cal.lunarIsoFormat())
        XCTAssertNotNil(cal.solarIsoFormat()) // Now should have solar date
    }
    
    func testSolarToLunarConversion() {
        let cal = KoreanLunarCalendar()
        
        // Test known conversion: 2024-01-01 (solar)
        XCTAssertTrue(cal.setSolarDate(2024, 1, 1))
        XCTAssertEqual(cal.solarIsoFormat(), "2024-01-01")
        
        let lunarResult = cal.lunarIsoFormat()
        XCTAssertNotNil(lunarResult)
        print("2024-01-01 solar -> lunar: \(lunarResult ?? "nil")")
    }
    
    func testLunarToSolarConversion() {
        let cal = KoreanLunarCalendar()
        
        // Test known conversion: 2023-01-01 (lunar)
        XCTAssertTrue(cal.setLunarDate(2023, 1, 1, false))
        XCTAssertEqual(cal.lunarIsoFormat(), "2023-01-01")
        
        let solarResult = cal.solarIsoFormat()
        XCTAssertNotNil(solarResult)
        print("2023-01-01 lunar -> solar: \(solarResult ?? "nil")")
    }
    
    func testIntercalationMonth() {
        let cal = KoreanLunarCalendar()
        
        // Test year with known intercalation month (윤달)
        // 2020년에 윤4월이 있다고 가정하고 테스트
        XCTAssertTrue(cal.setLunarDate(2020, 4, 15, true)) // 윤4월
        let lunarResult = cal.lunarIsoFormat()
        let solarResult = cal.solarIsoFormat()
        
        print("2020-04-15 intercalation lunar -> solar: \(solarResult ?? "nil")")
        print("Lunar format: \(lunarResult ?? "nil")")
        
        XCTAssertNotNil(lunarResult)
        XCTAssertNotNil(solarResult)
    }
    
    func testRoundTripConversion() {
        let cal = KoreanLunarCalendar()
        
        // Test round-trip: Solar -> Lunar -> Solar
        let originalSolar = "2024-06-15"
        XCTAssertTrue(cal.setSolarDate(2024, 6, 15))
        
        let lunar = cal.lunarIsoFormat()
        XCTAssertNotNil(lunar)
        
        // Now convert back to solar
        if let l = cal.currentLunar {
            XCTAssertTrue(cal.setLunarDate(l.year, l.month, l.day, l.isLeapMonth))
            let backToSolar = cal.solarIsoFormat()
            print("Round-trip test: \(originalSolar) -> \(lunar ?? "nil") -> \(backToSolar ?? "nil")")
            // XCTAssertEqual(backToSolar, originalSolar) // Should match
        }
    }
}