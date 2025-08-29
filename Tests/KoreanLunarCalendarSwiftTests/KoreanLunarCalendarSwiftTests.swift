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
    
    func testKnownConversions() {
        let cal = KoreanLunarCalendar()
        
        // Test case from original Java README: 2017-06-24 solar -> 2017-05-01 intercalation lunar
        XCTAssertTrue(cal.setSolarDate(2017, 6, 24))
        XCTAssertEqual(cal.solarIsoFormat(), "2017-06-24")
        let lunarResult = cal.lunarIsoFormat()
        print("Known conversion test: 2017-06-24 solar -> \(lunarResult ?? "nil")")
        // Expected: 2017-05-01 Intercalation
        XCTAssertEqual(lunarResult, "2017-05-01 Intercalation")
    }
    
    func testMoreKnownConversions() {
        let cal = KoreanLunarCalendar()
        
        // Test multiple known accurate conversions
        let testCases: [(solar: (Int, Int, Int), lunar: (Int, Int, Int, Bool), description: String)] = [
            // Format: (solarY, solarM, solarD) -> (lunarY, lunarM, lunarD, isIntercalation)
            ((2020, 1, 1), (2019, 12, 7, false), "New Year 2020"),
            ((2023, 1, 22), (2023, 1, 1, false), "Korean New Year 2023"), 
            ((2024, 2, 10), (2024, 1, 1, false), "Korean New Year 2024"),
            ((2020, 6, 6), (2020, 4, 15, true), "2020 Intercalation month test")
        ]
        
        for testCase in testCases {
            // Test Solar -> Lunar
            XCTAssertTrue(cal.setSolarDate(testCase.solar.0, testCase.solar.1, testCase.solar.2), 
                         "Failed to set solar date for: \(testCase.description)")
            
            if let lunar = cal.currentLunar {
                XCTAssertEqual(lunar.year, testCase.lunar.0, 
                              "\(testCase.description) - Lunar year mismatch")
                XCTAssertEqual(lunar.month, testCase.lunar.1, 
                              "\(testCase.description) - Lunar month mismatch") 
                XCTAssertEqual(lunar.day, testCase.lunar.2, 
                              "\(testCase.description) - Lunar day mismatch")
                XCTAssertEqual(lunar.isLeapMonth, testCase.lunar.3, 
                              "\(testCase.description) - Lunar intercalation mismatch")
                
                print("\(testCase.description): \(testCase.solar.0)-\(testCase.solar.1)-\(testCase.solar.2) -> \(lunar.year)-\(lunar.month)-\(lunar.day)\(lunar.isLeapMonth ? " Intercalation" : "")")
            } else {
                XCTFail("Failed to convert solar date for: \(testCase.description)")
            }
            
            // Test Lunar -> Solar (reverse conversion)
            XCTAssertTrue(cal.setLunarDate(testCase.lunar.0, testCase.lunar.1, testCase.lunar.2, testCase.lunar.3),
                         "Failed to set lunar date for: \(testCase.description)")
            
            if let solar = cal.currentSolar {
                XCTAssertEqual(solar.year, testCase.solar.0, 
                              "\(testCase.description) - Solar year mismatch (reverse)")
                XCTAssertEqual(solar.month, testCase.solar.1, 
                              "\(testCase.description) - Solar month mismatch (reverse)")
                XCTAssertEqual(solar.day, testCase.solar.2, 
                              "\(testCase.description) - Solar day mismatch (reverse)")
            } else {
                XCTFail("Failed to convert lunar date for: \(testCase.description)")
            }
        }
    }
    
    func testRoundTripConversion() {
        let cal = KoreanLunarCalendar()
        
        // Test multiple round-trips with different dates
        let testDates = [
            (2024, 6, 15),
            (2023, 12, 25), // Christmas
            (2022, 8, 15), // Korean independence day
            (2021, 10, 3),  // Korean national foundation day
        ]
        
        for (year, month, day) in testDates {
            let originalSolar = "\(year)-\(String(format: "%02d", month))-\(String(format: "%02d", day))"
            
            // Solar -> Lunar -> Solar
            XCTAssertTrue(cal.setSolarDate(year, month, day), "Failed to set solar date: \(originalSolar)")
            
            let lunar = cal.lunarIsoFormat()
            XCTAssertNotNil(lunar, "Failed to get lunar format for: \(originalSolar)")
            
            // Convert back to solar
            if let l = cal.currentLunar {
                XCTAssertTrue(cal.setLunarDate(l.year, l.month, l.day, l.isLeapMonth), 
                             "Failed to convert back to solar for: \(originalSolar)")
                let backToSolar = cal.solarIsoFormat()
                print("Round-trip test: \(originalSolar) -> \(lunar ?? "nil") -> \(backToSolar ?? "nil")")
                XCTAssertEqual(backToSolar, originalSolar, "Round-trip failed for: \(originalSolar)")
            } else {
                XCTFail("No lunar date available for round-trip test: \(originalSolar)")
            }
        }
    }
    
    func testEdgeCases() {
        let cal = KoreanLunarCalendar()
        
        // Test boundary dates
        XCTAssertTrue(cal.setSolarDate(1000, 2, 13), "Failed to set minimum solar date")
        XCTAssertTrue(cal.setSolarDate(2050, 12, 31), "Failed to set maximum solar date")
        
        // Test invalid dates
        XCTAssertFalse(cal.setSolarDate(999, 1, 1), "Should reject year < 1000")
        XCTAssertFalse(cal.setSolarDate(2051, 1, 1), "Should reject year > 2050") 
        XCTAssertFalse(cal.setSolarDate(2020, 13, 1), "Should reject month > 12")
        XCTAssertFalse(cal.setSolarDate(2020, 1, 32), "Should reject day > 31")
        
        // Test invalid lunar dates
        XCTAssertFalse(cal.setLunarDate(2019, 12, 6, true), "Should reject invalid intercalation")
        XCTAssertFalse(cal.setLunarDate(2020, 5, 15, true), "Should reject wrong intercalation month")
    }
}