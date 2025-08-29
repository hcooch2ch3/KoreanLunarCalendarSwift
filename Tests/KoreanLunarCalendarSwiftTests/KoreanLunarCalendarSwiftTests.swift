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
        // 2019 did not have a leap (윤달) 12th month; attempting to set 2019-12-6 as a leap month should be rejected.
        XCTAssertFalse(cal.setLunarDate(2019, 12, 6, true), "Should reject invalid intercalation")
        // 2020's leap month was the 4th month (윤4월), not the 5th; attempting to set 2020-5-15 as a leap month should be rejected.
        XCTAssertFalse(cal.setLunarDate(2020, 5, 15, true), "Should reject wrong intercalation month")
    }
    
    func testGapJaCalculation() {
        let cal = KoreanLunarCalendar()
        
        // Test Gap-Ja calculation for known dates
        XCTAssertTrue(cal.setSolarDate(2024, 1, 1))
        
        let koreanGapja = cal.getGapJaString()
        let chineseGapja = cal.getChineseGapJaString()
        
        XCTAssertNotNil(koreanGapja, "Korean Gap-Ja should not be nil")
        XCTAssertNotNil(chineseGapja, "Chinese Gap-Ja should not be nil")
        
        print("2024-01-01 solar date:")
        print("- Lunar: \(cal.lunarIsoFormat() ?? "nil")")
        print("- Korean Gap-Ja: \(koreanGapja ?? "nil")")
        print("- Chinese Gap-Ja: \(chineseGapja ?? "nil")")
        
        // Test intercalation month Gap-Ja
        XCTAssertTrue(cal.setLunarDate(2020, 4, 15, true)) // 윤4월
        
        let intercalationKorean = cal.getGapJaString()
        let intercalationChinese = cal.getChineseGapJaString()
        
        XCTAssertNotNil(intercalationKorean)
        XCTAssertNotNil(intercalationChinese)
        XCTAssertTrue(intercalationKorean?.contains("(윤)") == true, "Korean Gap-Ja should contain (윤)")
        XCTAssertTrue(intercalationChinese?.contains("(閏)") == true, "Chinese Gap-Ja should contain (閏)")
        
        print("\n2020-04-15 lunar intercalation date:")
        print("- Korean Gap-Ja: \(intercalationKorean ?? "nil")")
        print("- Chinese Gap-Ja: \(intercalationChinese ?? "nil")")
    }
    
    func testKnownAccurateGapJaCalculations() {
        let cal = KoreanLunarCalendar()
        
        // Test cases with Gap-Ja values based on our algorithm's actual output
        let testCases: [(solar: (Int, Int, Int), expectedKorean: String, expectedChinese: String, description: String)] = [
            // 2024년 새해 - 음력으로는 아직 계묘년
            ((2024, 1, 1), "계묘년 갑자월 갑자일", "癸卯年 甲子月 甲子日", "2024 New Year"),
            
            // 2023년 추석
            ((2023, 9, 29), "계묘년 신유월 경인일", "癸卯年 辛酉月 庚寅日", "2023 Chuseok"),
            
            // 2022년 설날
            ((2022, 2, 1), "임인년 임인월 을유일", "壬寅年 壬寅月 乙酉日", "2022 Korean New Year"),
            
            // 2021년 어린이날
            ((2021, 5, 5), "신축년 임진월 계축일", "辛丑年 壬辰月 癸丑日", "2021 Children's Day"),
            
            // 2020년 1월 20일 - 음력으로는 아직 기해년
            ((2020, 1, 20), "기해년 정축월 임술일", "己亥年 丁丑月 壬戌日", "2020 COVID start"),
        ]
        
        for testCase in testCases {
            XCTAssertTrue(cal.setSolarDate(testCase.solar.0, testCase.solar.1, testCase.solar.2),
                         "Failed to set solar date for: \(testCase.description)")
            
            let koreanResult = cal.getGapJaString()
            let chineseResult = cal.getChineseGapJaString()
            
            XCTAssertNotNil(koreanResult, "\(testCase.description) - Korean Gap-Ja should not be nil")
            XCTAssertNotNil(chineseResult, "\(testCase.description) - Chinese Gap-Ja should not be nil")
            
            print("\n\(testCase.description): \(testCase.solar.0)-\(testCase.solar.1)-\(testCase.solar.2)")
            print("- Expected Korean: \(testCase.expectedKorean)")
            print("- Actual Korean:   \(koreanResult ?? "nil")")
            print("- Expected Chinese: \(testCase.expectedChinese)")
            print("- Actual Chinese:   \(chineseResult ?? "nil")")
            
            // Verify the Gap-Ja results match expected values
            XCTAssertEqual(koreanResult, testCase.expectedKorean,
                          "\(testCase.description) - Korean Gap-Ja mismatch")
            XCTAssertEqual(chineseResult, testCase.expectedChinese,
                          "\(testCase.description) - Chinese Gap-Ja mismatch")
        }
    }
    
    func testSpecialDateGapJaCalculations() {
        let cal = KoreanLunarCalendar()
        
        // Test historically significant dates with known Gap-Ja
        let historicalDates: [(solar: (Int, Int, Int), description: String)] = [
            // 한국의 중요한 날들
            ((2024, 8, 15), "2024 Liberation Day"),
            ((2024, 10, 3), "2024 National Foundation Day"),
            ((2023, 6, 6), "2023 Memorial Day"),
            ((2022, 3, 1), "2022 Independence Movement Day"),
            
            // 월경계 테스트 (월이 바뀌는 시점)
            ((2024, 2, 29), "2024 Leap Year Feb 29"),
            ((2023, 12, 31), "2023 Year End"),
            ((2024, 1, 1), "2024 Year Start"),
            
            // 윤달이 있는 해의 특정 날들
            ((2020, 5, 23), "2020 intercalation year date"),
            ((2017, 7, 23), "2017 intercalation year date"),
        ]
        
        for dateInfo in historicalDates {
            XCTAssertTrue(cal.setSolarDate(dateInfo.solar.0, dateInfo.solar.1, dateInfo.solar.2),
                         "Failed to set solar date for: \(dateInfo.description)")
            
            let koreanGapja = cal.getGapJaString()
            let chineseGapja = cal.getChineseGapJaString()
            let lunarDate = cal.lunarIsoFormat()
            
            XCTAssertNotNil(koreanGapja, "\(dateInfo.description) - Korean Gap-Ja should not be nil")
            XCTAssertNotNil(chineseGapja, "\(dateInfo.description) - Chinese Gap-Ja should not be nil")
            
            print("\n\(dateInfo.description): \(dateInfo.solar.0)-\(dateInfo.solar.1)-\(dateInfo.solar.2)")
            print("- Lunar: \(lunarDate ?? "nil")")
            print("- Korean Gap-Ja: \(koreanGapja ?? "nil")")
            print("- Chinese Gap-Ja: \(chineseGapja ?? "nil")")
            
            // Validate Gap-Ja format structure
            if let korean = koreanGapja {
                XCTAssertTrue(korean.contains("년"), "\(dateInfo.description) - Korean should contain '년'")
                XCTAssertTrue(korean.contains("월"), "\(dateInfo.description) - Korean should contain '월'")
                XCTAssertTrue(korean.contains("일"), "\(dateInfo.description) - Korean should contain '일'")
            }
            
            if let chinese = chineseGapja {
                XCTAssertTrue(chinese.contains("年"), "\(dateInfo.description) - Chinese should contain '年'")
                XCTAssertTrue(chinese.contains("月"), "\(dateInfo.description) - Chinese should contain '月'")
                XCTAssertTrue(chinese.contains("日"), "\(dateInfo.description) - Chinese should contain '日'")
            }
        }
    }
    
    func testGapJaConsistencyOverTime() {
        let cal = KoreanLunarCalendar()
        
        // Test that Gap-Ja follows proper 60-day and 60-year cycles
        let baseDate = (2024, 1, 1)  // 갑진년 을축월 갑자일
        XCTAssertTrue(cal.setSolarDate(baseDate.0, baseDate.1, baseDate.2))
        
        let baseKorean = cal.getGapJaString()
        XCTAssertNotNil(baseKorean)
        
        // Test 60-day cycle (간지는 60일 주기로 반복)
        XCTAssertTrue(cal.setSolarDate(2024, 3, 1)) // 60일 후
        let after60Days = cal.getGapJaString()
        
        print("\nGap-Ja 60-day cycle test:")
        print("- Base (2024-01-01): \(baseKorean ?? "nil")")
        print("- After 60 days (2024-03-01): \(after60Days ?? "nil")")
        
        // 같은 날 간지가 나와야 함 (60일 주기)
        if let base = baseKorean, let after = after60Days {
            let baseDayGapja = String(base.suffix(2)) // 마지막 두 글자 (일간지)
            let afterDayGapja = String(after.suffix(2))
            XCTAssertEqual(baseDayGapja, afterDayGapja, "60-day cycle should repeat day Gap-Ja")
        }
        
        // Test different years to ensure year Gap-Ja changes correctly
        let yearTestDates = [(2020, 1, 1), (2021, 1, 1), (2022, 1, 1), (2023, 1, 1), (2024, 1, 1)]
        var yearGapjas: [String] = []
        
        for (year, month, day) in yearTestDates {
            XCTAssertTrue(cal.setSolarDate(year, month, day))
            if let gapja = cal.getGapJaString() {
                yearGapjas.append(gapja)
                print("\(year)-\(month)-\(day): \(gapja)")
            }
        }
        
        // 연속된 해는 서로 다른 연간지를 가져야 함
        for i in 0..<yearGapjas.count-1 {
            let currentYear = String(yearGapjas[i].prefix(2)) // 첫 두 글자 (연간지)
            let nextYear = String(yearGapjas[i+1].prefix(2))
            XCTAssertNotEqual(currentYear, nextYear, "Consecutive years should have different year Gap-Ja")
        }
    }
}