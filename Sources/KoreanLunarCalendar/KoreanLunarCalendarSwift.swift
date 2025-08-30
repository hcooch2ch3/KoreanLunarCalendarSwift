import Foundation

// MARK: - Debug Logging
internal func debugLog(_ message: String, function: String = #function, line: Int = #line) {
    #if DEBUG
        if ProcessInfo.processInfo.environment["KLC_DEV"] != nil {
            print("[KoreanLunarCalendar] \(function):\(line) - \(message)")
        }
    #endif
}

public struct LunarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool
    public init(year: Int, month: Int, day: Int, isLeapMonth: Bool) {
        self.year = year
        self.month = month
        self.day = day
        self.isLeapMonth = isLeapMonth
    }
}

public struct SolarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

enum DataLoaderError: Error {
    case resourceNotFound
    case decodeFailed
    case invalidYearRange
    case invalidMonthRange
}

internal struct LunarTableMetadata: Codable {
    let version: String
    let source: String
    let yearRange: YearRange
    let lunarRange: DateRange
    let gregorianRange: DateRange
    let description: String

    enum CodingKeys: String, CodingKey {
        case version, source, description
        case yearRange = "year_range"
        case lunarRange = "lunar_range"
        case gregorianRange = "gregorian_range"
    }
}

struct YearRange: Codable {
    let start: Int
    let end: Int
}

struct DateRange: Codable {
    let start: String
    let end: String
}

struct LunarConstants: Codable {
    let lunarBigMonthDays: Int
    let lunarSmallMonthDays: Int
    let solarYearDays: Int
    let lunarYearDays: Int

    enum CodingKeys: String, CodingKey {
        case lunarBigMonthDays = "lunar_big_month_days"
        case lunarSmallMonthDays = "lunar_small_month_days"
        case solarYearDays = "solar_year_days"
        case lunarYearDays = "lunar_year_days"
    }
}

struct BitEncoding: Codable {
    let description: String
    let bitPositions: BitPositions
    let extractionFormulas: ExtractionFormulas

    enum CodingKeys: String, CodingKey {
        case description
        case bitPositions = "bit_positions"
        case extractionFormulas = "extraction_formulas"
    }
}

struct BitPositions: Codable {
    let monthPattern: String
    let intercalationMonth: String
    let totalLunarDays: String
    let solarLeapYear: String

    enum CodingKeys: String, CodingKey {
        case monthPattern = "month_pattern"
        case intercalationMonth = "intercalation_month"
        case totalLunarDays = "total_lunar_days"
        case solarLeapYear = "solar_leap_year"
    }
}

struct ExtractionFormulas: Codable {
    let intercalationMonth: String
    let totalLunarDays: String
    let solarLeapYear: String
    let monthDays: String

    enum CodingKeys: String, CodingKey {
        case intercalationMonth = "intercalation_month"
        case totalLunarDays = "total_lunar_days"
        case solarLeapYear = "solar_leap_year"
        case monthDays = "month_days"
    }
}

struct LunarTable: Codable {
    let metadata: LunarTableMetadata
    let constants: LunarConstants
    let data: [UInt32]
    let bitEncoding: BitEncoding
    let usageNote: String

    enum CodingKeys: String, CodingKey {
        case metadata, constants, data
        case bitEncoding = "bit_encoding"
        case usageNote = "usage_note"
    }
}

final class DataLoader {
    static let shared = DataLoader()
    private(set) var isLoaded = false
    private(set) var lunarTable: LunarTable?
    
    // MARK: - Constants (from original Java)
    private static let koreanLunarBaseYear = 1000
    private static let solarLunarDayDiff = 43
    private static let lunarSmallMonthDay = 29
    private static let lunarBigMonthDay = 30
    private static let solarSmallYearDay = 365
    private static let solarBigYearDay = 366
    private static let solarDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] // Standard month days

    // MARK: - Performance Optimization: Lazy Lookup Tables
    private var yearTotalDaysCache: [Int: Int] = [:]
    private var monthDaysCache: [String: Int] = [:]
    private var yearCumulativeDaysCache: [Int: Int] = [:]
    private let cacheQueue = DispatchQueue(label: "com.koreanlunar.cache", attributes: .concurrent)

    private init() {}

    func loadIfNeeded() throws {
        guard !isLoaded else { return }
        guard let url = Bundle.module.url(forResource: "lunar_table", withExtension: "json") else {
            throw DataLoaderError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        do {
            self.lunarTable = try JSONDecoder().decode(LunarTable.self, from: data)
            self.isLoaded = true
        } catch {
            throw DataLoaderError.decodeFailed
        }
    }

    func getData(for year: Int) throws -> UInt32 {
        try loadIfNeeded()
        guard let table = lunarTable else {
            throw DataLoaderError.decodeFailed
        }

        let startYear = table.metadata.yearRange.start
        let endYear = table.metadata.yearRange.end

        guard year >= startYear && year <= endYear else {
            throw DataLoaderError.invalidYearRange
        }

        let index = year - startYear
        return table.data[index]
    }

    func getIntercalationMonth(for year: Int) throws -> Int {
        let yearData = try getData(for: year)
        return Int((yearData >> 12) & 0xF)
    }

    func getTotalLunarDays(for year: Int) throws -> Int {
        let yearData = try getData(for: year)
        return Int((yearData >> 17) & 0x1FF)
    }

    func isSolarLeapYear(_ year: Int) throws -> Bool {
        let yearData = try getData(for: year)
        return (yearData >> 30) & 0x1 == 1
    }

    func getLunarMonthDays(year: Int, month: Int) throws -> Int {
        guard month >= 1 && month <= 12 else {
            throw DataLoaderError.invalidMonthRange
        }

        let yearData = try getData(for: year)
        guard let constants = lunarTable?.constants else {
            throw DataLoaderError.decodeFailed
        }

        let bitPosition = 12 - month
        let isBigMonth = (yearData >> bitPosition) & 0x1 == 1

        return isBigMonth ? constants.lunarBigMonthDays : constants.lunarSmallMonthDays
    }

    func getIntercalationMonthDays(year: Int) throws -> Int {
        let intercalationMonth = try getIntercalationMonth(for: year)
        guard intercalationMonth > 0 else {
            return 0  // 윤달이 없는 해
        }

        let yearData = try getData(for: year)
        guard let constants = lunarTable?.constants else {
            throw DataLoaderError.decodeFailed
        }

        // 윤달의 일수는 16비트 위치에 저장
        let isIntercalationBig = (yearData >> 16) & 0x1 == 1
        return isIntercalationBig ? constants.lunarBigMonthDays : constants.lunarSmallMonthDays
    }
    
    // MARK: - Helper Methods (ported from Java)
    
    /// Get lunar days for specific month (including intercalation handling)
    func getLunarDays(year: Int, month: Int, isIntercalation: Bool) throws -> Int {
        let yearData = try getData(for: year)
        let intercalationMonth = try getIntercalationMonth(for: year)
        
        if isIntercalation && intercalationMonth == month {
            // 윤달의 일수
            let isIntercalationBig = (yearData >> 16) & 0x1 == 1
            return isIntercalationBig ? Self.lunarBigMonthDay : Self.lunarSmallMonthDay
        } else {
            // 일반 월의 일수
            let bitPosition = 12 - month
            let isBigMonth = (yearData >> bitPosition) & 0x1 == 1
            return isBigMonth ? Self.lunarBigMonthDay : Self.lunarSmallMonthDay
        }
    }
    
    /// Check if given year is solar intercalation (leap) year
    func isSolarIntercalationYear(_ year: Int) throws -> Bool {
        let yearData = try getData(for: year)
        return (yearData >> 30) & 0x1 == 1
    }
    
    /// Get solar days in a year
    func getSolarDays(year: Int) throws -> Int {
        return try isSolarIntercalationYear(year) ? Self.solarBigYearDay : Self.solarSmallYearDay
    }
    
    /// Get solar days in a specific month
    func getSolarDays(year: Int, month: Int) throws -> Int {
        guard month >= 1 && month <= 12 else {
            throw DataLoaderError.invalidMonthRange
        }
        
        let isLeapYear = try isSolarIntercalationYear(year)
        if month == 2 && isLeapYear {
            return 29 // leap February (29 days)
        } else {
            return Self.solarDays[month - 1]
        }
    }
    
    /// Get lunar days before base year (cumulative) - Optimized version
    func getLunarDaysBeforeBaseYear(_ year: Int, useOptimization: Bool = false) throws -> Int {
        guard year >= Self.koreanLunarBaseYear else { return 0 }
        
        if useOptimization {
            return try cacheQueue.sync {
                if let cached = yearCumulativeDaysCache[year] {
                    return cached
                }
                
                var days = 0
                for baseYear in Self.koreanLunarBaseYear...year {
                    days += try getTotalLunarDaysOptimized(for: baseYear)
                }
                
                yearCumulativeDaysCache[year] = days
                return days
            }
        } else {
            var days = 0
            for baseYear in Self.koreanLunarBaseYear...year {
                days += try getTotalLunarDays(for: baseYear)
            }
            return days
        }
    }
    
    /// Optimized version of getTotalLunarDays with caching
    private func getTotalLunarDaysOptimized(for year: Int) throws -> Int {
        if let cached = yearTotalDaysCache[year] {
            return cached
        }
        
        let days = try getTotalLunarDays(for: year)
        yearTotalDaysCache[year] = days
        return days
    }
    
    /// Get lunar days before base month (cumulative) - Optimized version
    func getLunarDaysBeforeBaseMonth(year: Int, month: Int, includeIntercalation: Bool, useOptimization: Bool = false) throws -> Int {
        guard year >= Self.koreanLunarBaseYear && month >= 1 else {
            return 0
        }
        
        if useOptimization {
            let cacheKey = "\(year)-\(month)-\(includeIntercalation)"
            return try cacheQueue.sync {
                if let cached = monthDaysCache[cacheKey] {
                    return cached
                }
                
                var days = 0
                for baseMonth in 1...month {
                    days += try getLunarDays(year: year, month: baseMonth, isIntercalation: false)
                }
                
                if includeIntercalation {
                    let intercalationMonth = try getIntercalationMonth(for: year)
                    if intercalationMonth > 0 && intercalationMonth <= month {
                        days += try getLunarDays(year: year, month: intercalationMonth, isIntercalation: true)
                    }
                }
                
                monthDaysCache[cacheKey] = days
                return days
            }
        } else {
            var days = 0
            for baseMonth in 1...month {
                days += try getLunarDays(year: year, month: baseMonth, isIntercalation: false)
            }
            
            if includeIntercalation {
                let intercalationMonth = try getIntercalationMonth(for: year)
                if intercalationMonth > 0 && intercalationMonth <= month {
                    days += try getLunarDays(year: year, month: intercalationMonth, isIntercalation: true)
                }
            }
            
            return days
        }
    }
    
    /// Get solar days before base year (cumulative)
    func getSolarDaysBeforeBaseYear(_ year: Int) throws -> Int {
        var days = 0
        guard year >= Self.koreanLunarBaseYear else { return 0 }
        
        for baseYear in Self.koreanLunarBaseYear...year {
            days += try getSolarDays(year: baseYear)
        }
        return days
    }
    
    /// Get solar days before base month (cumulative)
    func getSolarDaysBeforeBaseMonth(year: Int, month: Int) throws -> Int {
        var days = 0
        guard month >= 1 else { return 0 }
        
        // Include target month (matching Java: baseMonth < month + 1)
        for baseMonth in 1...month {
            days += try getSolarDays(year: year, month: baseMonth)
        }
        return days
    }
    
    /// Get solar absolute days from base year
    func getSolarAbsDays(year: Int, month: Int, day: Int, useOptimization: Bool = false) throws -> Int {
        var days = try getSolarDaysBeforeBaseYear(year - 1)
        days += try getSolarDaysBeforeBaseMonth(year: year, month: month - 1) 
        days += day
        days -= Self.solarLunarDayDiff
        return days
    }
    
    /// Get lunar absolute days from base year
    func getLunarAbsDays(year: Int, month: Int, day: Int, isIntercalation: Bool, useOptimization: Bool = false) throws -> Int {
        var days = try getLunarDaysBeforeBaseYear(year - 1, useOptimization: useOptimization)
        days += try getLunarDaysBeforeBaseMonth(year: year, month: month - 1, includeIntercalation: true, useOptimization: useOptimization)
        days += day
        
        let intercalationMonth = try getIntercalationMonth(for: year)
        if isIntercalation && intercalationMonth == month {
            days += try getLunarDays(year: year, month: month, isIntercalation: false)
        }
        
        return days
    }
}

public final class KoreanLunarCalendar {
    internal var currentSolar: SolarDate?
    internal var currentLunar: LunarDate?
    
    /// Performance optimization flag - enables lazy lookup tables when true
    private let enableOptimization: Bool

    /// Initialize KoreanLunarCalendar
    /// - Parameter enableOptimization: Enable lazy lookup tables for better performance (default: false)
    public init(enableOptimization: Bool = false) {
        self.enableOptimization = enableOptimization
    }

    /// 양력 -> 음력 (성공 시 내부 상태에 저장)
    @discardableResult
    public func setSolarDate(_ year: Int, _ month: Int, _ day: Int) -> Bool {
        do {
            try DataLoader.shared.loadIfNeeded()
            
            // Input validation
            guard year >= 1000 && year <= 2050 else { return false }
            guard month >= 1 && month <= 12 else { return false }
            guard day >= 1 && day <= 31 else { return false }
            
            debugLog("Converting solar date: \(year)-\(month)-\(day)")
            
            // Convert using ported Java algorithm
            let result = try setLunarDateBySolarDate(solarYear: year, solarMonth: month, solarDay: day)
            
            self.currentSolar = SolarDate(year: year, month: month, day: day)
            self.currentLunar = result
            return true
        } catch {
            debugLog("Error converting solar date: \(error)")
            return false
        }
    }
    
    /// Core conversion: Solar -> Lunar (ported from Java)
    private func setLunarDateBySolarDate(solarYear: Int, solarMonth: Int, solarDay: Int) throws -> LunarDate {
        let absDays = try DataLoader.shared.getSolarAbsDays(year: solarYear, month: solarMonth, day: solarDay)
        
        var lunarYear = 0
        var lunarMonth = 0
        var lunarDay = 0
        var isIntercalation = false
        
        // Determine lunar year
        let firstDayOfYear = try DataLoader.shared.getLunarAbsDays(year: solarYear, month: 1, day: 1, isIntercalation: false, useOptimization: enableOptimization)
        lunarYear = absDays >= firstDayOfYear ? solarYear : solarYear - 1
        
        // Find lunar month by iterating backwards
        for month in stride(from: 12, through: 1, by: -1) {
            let absDaysByMonth = try DataLoader.shared.getLunarAbsDays(year: lunarYear, month: month, day: 1, isIntercalation: false, useOptimization: enableOptimization)
            if absDays >= absDaysByMonth {
                lunarMonth = month
                
                // Check for intercalation month
                let intercalationMonth = try DataLoader.shared.getIntercalationMonth(for: lunarYear)
                if intercalationMonth == month {
                    let intercalationStartDays = try DataLoader.shared.getLunarAbsDays(year: lunarYear, month: month, day: 1, isIntercalation: true, useOptimization: enableOptimization)
                    isIntercalation = absDays >= intercalationStartDays
                }
                
                let lunarAbsDays = try DataLoader.shared.getLunarAbsDays(year: lunarYear, month: lunarMonth, day: 1, isIntercalation: isIntercalation, useOptimization: enableOptimization)
                lunarDay = absDays - lunarAbsDays + 1
                break
            }
        }
        
        debugLog("Converted to lunar: \(lunarYear)-\(lunarMonth)-\(lunarDay) (intercalation: \(isIntercalation))")
        
        return LunarDate(year: lunarYear, month: lunarMonth, day: lunarDay, isLeapMonth: isIntercalation)
    }

    /// 음력 → 양력 (성공 시 내부 상태에 저장)
    @discardableResult
    public func setLunarDate(_ year: Int, _ month: Int, _ day: Int, _ intercalation: Bool) -> Bool {
        do {
            try DataLoader.shared.loadIfNeeded()
            
            // Input validation
            guard year >= 1000 && year <= 2050 else { return false }
            guard month >= 1 && month <= 12 else { return false }
            guard day >= 1 && day <= 31 else { return false }

            // 윤달 유효성 검증
            let intercalationMonth = try DataLoader.shared.getIntercalationMonth(for: year)
            if intercalation && intercalationMonth != month {
                debugLog(
                    "Invalid intercalation: Year \(year) has intercalation in month \(intercalationMonth), not \(month)"
                )
                return false
            }
            if intercalation && intercalationMonth == 0 {
                debugLog("Invalid intercalation: Year \(year) has no intercalation month")
                return false
            }

            // 해당 월의 일수 검증
            let monthDays = try DataLoader.shared.getLunarDays(year: year, month: month, isIntercalation: intercalation)
            if day > monthDays {
                debugLog(
                    "Invalid day: Month \(month)\(intercalation ? " (intercalation)" : "") in year \(year) has \(monthDays) days, not \(day)"
                )
                return false
            }
            
            debugLog("Converting lunar date: \(year)-\(month)-\(day) (intercalation: \(intercalation))")
            
            // Convert using ported Java algorithm
            let result = try setSolarDateByLunarDate(lunarYear: year, lunarMonth: month, lunarDay: day, isIntercalation: intercalation)

            self.currentLunar = LunarDate(year: year, month: month, day: day, isLeapMonth: intercalation)
            self.currentSolar = result
            return true
        } catch {
            debugLog("Error converting lunar date: \(error)")
            return false
        }
    }
    
    /// Core conversion: Lunar -> Solar (ported from Java)
    private func setSolarDateByLunarDate(lunarYear: Int, lunarMonth: Int, lunarDay: Int, isIntercalation: Bool) throws -> SolarDate {
        let absDays = try DataLoader.shared.getLunarAbsDays(year: lunarYear, month: lunarMonth, day: lunarDay, isIntercalation: isIntercalation, useOptimization: enableOptimization)
        
        var solarYear = 0
        var solarMonth = 0
        var solarDay = 0
        
        // Determine solar year
        let nextYearFirstDay = try DataLoader.shared.getSolarAbsDays(year: lunarYear + 1, month: 1, day: 1)
        solarYear = absDays < nextYearFirstDay ? lunarYear : lunarYear + 1
        
        // Find solar month by iterating backwards
        for month in stride(from: 12, through: 1, by: -1) {
            let absDaysByMonth = try DataLoader.shared.getSolarAbsDays(year: solarYear, month: month, day: 1)
            if absDays >= absDaysByMonth {
                solarMonth = month
                solarDay = absDays - absDaysByMonth + 1
                break
            }
        }
        
        debugLog("Converted to solar: \(solarYear)-\(solarMonth)-\(solarDay)")
        
        return SolarDate(year: solarYear, month: solarMonth, day: solarDay)
    }

    public func lunarIsoFormat() -> String? {
        guard let l = currentLunar else { return nil }
        return String(
            format: "%04d-%02d-%02d%@", l.year, l.month, l.day,
            l.isLeapMonth ? " Intercalation" : "")
    }

    public func solarIsoFormat() -> String? {
        guard let s = currentSolar else { return nil }
        return String(format: "%04d-%02d-%02d", s.year, s.month, s.day)
    }

    // MARK: - Gap-Ja (간지) Calculation
    
    /// Korean Celestial Stems (천간)
    private static let koreanCheongan = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"]
    
    /// Korean Earthly Branches (지지)  
    private static let koreanGanji = ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"]
    
    /// Chinese Celestial Stems (천간)
    private static let chineseCheongan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    
    /// Chinese Earthly Branches (지지)
    private static let chineseGanji = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    
    /// Korean Gap-Ja units
    private static let koreanGapjaUnit = ["년", "월", "일"]
    
    /// Chinese Gap-Ja units  
    private static let chineseGapjaUnit = ["年", "月", "日"]
    
    private func calculateGapJa() -> (year: (Int, Int), month: (Int, Int), day: (Int, Int))? {
        guard let lunar = currentLunar else { return nil }
        
        do {
            let absDays = try DataLoader.shared.getLunarAbsDays(
                year: lunar.year, 
                month: lunar.month, 
                day: lunar.day, 
                isIntercalation: lunar.isLeapMonth,
                useOptimization: enableOptimization
            )
            
            guard absDays > 0 else { return nil }
            
            // Year Gap-Ja (연간지)
            let yearCheonganIndex = ((lunar.year + 6) - 1000) % 10
            let yearGanjiIndex = ((lunar.year + 0) - 1000) % 12
            
            // Month Gap-Ja (월간지)
            var monthCount = lunar.month
            monthCount += 12 * (lunar.year - 1000)
            let monthCheonganIndex = (monthCount + 3) % 10
            let monthGanjiIndex = (monthCount + 1) % 12
            
            // Day Gap-Ja (일간지)  
            let dayCheonganIndex = (absDays + 4) % 10
            let dayGanjiIndex = (absDays + 2) % 12
            
            return (
                year: (yearCheonganIndex, yearGanjiIndex),
                month: (monthCheonganIndex, monthGanjiIndex),
                day: (dayCheonganIndex, dayGanjiIndex)
            )
        } catch {
            return nil
        }
    }
    
    /// 한글 간지 문자열 반환 ("갑자년 을축월 병인일")
    /// - Parameter isSolarGapja: true면 양력 기준 간지, false면 음력 기준 간지 (기본값: false)
    public func getGapJaString(isSolarGapja: Bool = false) -> String? {
        let gapja: (year: (Int, Int), month: (Int, Int), day: (Int, Int))?
        
        if isSolarGapja {
            gapja = calculateSolarGapJa()
        } else {
            gapja = calculateGapJa()
        }
        
        guard let gapja = gapja else { return nil }
        
        let yearGapja = Self.koreanCheongan[gapja.year.0] + Self.koreanGanji[gapja.year.1]
        let monthGapja = Self.koreanCheongan[gapja.month.0] + Self.koreanGanji[gapja.month.1]  
        let dayGapja = Self.koreanCheongan[gapja.day.0] + Self.koreanGanji[gapja.day.1]
        
        var result = "\(yearGapja)\(Self.koreanGapjaUnit[0]) \(monthGapja)\(Self.koreanGapjaUnit[1]) \(dayGapja)\(Self.koreanGapjaUnit[2])"
        
        // Add intercalation marker (only for lunar dates)
        if !isSolarGapja, let lunar = currentLunar, lunar.isLeapMonth {
            result += "(윤)"
        }
        
        return result
    }
    
    /// 한자 간지 문자열 반환 ("甲子年 乙丑月 丙寅日")
    /// - Parameter isSolarGapja: true면 양력 기준 간지, false면 음력 기준 간지 (기본값: false)
    public func getChineseGapJaString(isSolarGapja: Bool = false) -> String? {
        let gapja: (year: (Int, Int), month: (Int, Int), day: (Int, Int))?
        
        if isSolarGapja {
            gapja = calculateSolarGapJa()
        } else {
            gapja = calculateGapJa()
        }
        
        guard let gapja = gapja else { return nil }
        
        let yearGapja = Self.chineseCheongan[gapja.year.0] + Self.chineseGanji[gapja.year.1]
        let monthGapja = Self.chineseCheongan[gapja.month.0] + Self.chineseGanji[gapja.month.1]
        let dayGapja = Self.chineseCheongan[gapja.day.0] + Self.chineseGanji[gapja.day.1]
        
        var result = "\(yearGapja)\(Self.chineseGapjaUnit[0]) \(monthGapja)\(Self.chineseGapjaUnit[1]) \(dayGapja)\(Self.chineseGapjaUnit[2])"
        
        // Add intercalation marker (only for lunar dates)
        if !isSolarGapja, let lunar = currentLunar, lunar.isLeapMonth {
            result += "(閏)"
        }
        
        return result
    }
    
    /// Calculate Gap-Ja for solar date
    private func calculateSolarGapJa() -> (year: (Int, Int), month: (Int, Int), day: (Int, Int))? {
        guard let solar = currentSolar else { return nil }
        
        do {
            // Calculate absolute days from solar date
            let solarAbsDays = try DataLoader.shared.getSolarAbsDays(year: solar.year, month: solar.month, day: solar.day, useOptimization: enableOptimization)
            
            guard solarAbsDays > 0 else { return nil }
            
            // Year Gap-Ja for solar year
            let yearCheonganIndex = ((solar.year + 6) - 1000) % 10
            let yearGanjiIndex = ((solar.year + 0) - 1000) % 12
            
            // Month Gap-Ja for solar month
            var monthCount = solar.month
            monthCount += 12 * (solar.year - 1000)
            let monthCheonganIndex = (monthCount + 3) % 10
            let monthGanjiIndex = (monthCount + 1) % 12
            
            // Day Gap-Ja for solar day
            let dayCheonganIndex = (solarAbsDays + 4) % 10
            let dayGanjiIndex = (solarAbsDays + 2) % 12
            
            return (
                year: (yearCheonganIndex, yearGanjiIndex),
                month: (monthCheonganIndex, monthGanjiIndex),
                day: (dayCheonganIndex, dayGanjiIndex)
            )
        } catch {
            return nil
        }
    }
}
