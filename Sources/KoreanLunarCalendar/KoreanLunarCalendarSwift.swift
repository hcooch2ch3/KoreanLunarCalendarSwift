import Foundation

public struct LunarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool
    public init(year: Int, month: Int, day: Int, isLeapMonth: Bool) {
        self.year = year; self.month = month; self.day = day; self.isLeapMonth = isLeapMonth
    }
}

public struct SolarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public init(year: Int, month: Int, day: Int) {
        self.year = year; self.month = month; self.day = day
    }
}

enum DataLoaderError: Error { 
    case resourceNotFound
    case decodeFailed
    case invalidYearRange
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
            throw DataLoaderError.invalidYearRange
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
            return 0 // 윤달이 없는 해
        }
        
        let yearData = try getData(for: year)
        guard let constants = lunarTable?.constants else {
            throw DataLoaderError.decodeFailed
        }
        
        // 윤달의 일수는 16비트 위치에 저장
        let isIntercalationBig = (yearData >> 16) & 0x1 == 1
        return isIntercalationBig ? constants.lunarBigMonthDays : constants.lunarSmallMonthDays
    }
}

public final class KoreanLunarCalendar: Sendable {
    private var currentSolar: SolarDate?
    private var currentLunar: LunarDate?

    public init() {}

    /// 양력 -> 음력 (성공 시 내부 상태에 저장)
    @discardableResult
    public func setSolarDate(_ year: Int, _ month: Int, _ day: Int) -> Bool {
        do {
            try DataLoader.shared.loadIfNeeded()
            
            // 새로운 메서드들로 정보 추출
            let intercalationMonth = try DataLoader.shared.getIntercalationMonth(for: year)
            let totalDays = try DataLoader.shared.getTotalLunarDays(for: year)
            let isLeapYear = try DataLoader.shared.isSolarLeapYear(year)
            
            print("Year \(year): intercalation=\(intercalationMonth), totalDays=\(totalDays), isLeapYear=\(isLeapYear)")
            
            // 월별 일수 정보 출력 (테스트용)
            for month in 1...12 {
                let days = try DataLoader.shared.getLunarMonthDays(year: year, month: month)
                print("  Month \(month): \(days) days")
            }
            
            if intercalationMonth > 0 {
                let intercalationDays = try DataLoader.shared.getIntercalationMonthDays(year: year)
                print("  Intercalation month \(intercalationMonth): \(intercalationDays) days")
            }
            
            self.currentSolar = SolarDate(year: year, month: month, day: day)
            // TODO: 실제 변환 알고리즘 구현
            self.currentLunar = nil
            return true
        } catch {
            return false
        }
    }

    /// 음력 → 양력 (성공 시 내부 상태에 저장)
    @discardableResult
    public func setLunarDate(_ year: Int, _ month: Int, _ day: Int, _ intercalation: Bool) -> Bool {
        do {
            try DataLoader.shared.loadIfNeeded()
            
            // 윤달 유효성 검증
            let intercalationMonth = try DataLoader.shared.getIntercalationMonth(for: year)
            if intercalation && intercalationMonth != month {
                print("Invalid intercalation: Year \(year) has intercalation in month \(intercalationMonth), not \(month)")
                return false
            }
            if intercalation && intercalationMonth == 0 {
                print("Invalid intercalation: Year \(year) has no intercalation month")
                return false
            }
            
            // 해당 월의 일수 검증
            let monthDays: Int
            if intercalation {
                monthDays = try DataLoader.shared.getIntercalationMonthDays(year: year)
            } else {
                monthDays = try DataLoader.shared.getLunarMonthDays(year: year, month: month)
            }
            
            if day < 1 || day > monthDays {
                print("Invalid day: Month \(month)\(intercalation ? " (intercalation)" : "") in year \(year) has \(monthDays) days, not \(day)")
                return false
            }
            
            self.currentLunar = LunarDate(year: year, month: month, day: day, isLeapMonth: intercalation)
            // TODO: 실제 변환 알고리즘 구현
            self.currentSolar = nil
            return true
        } catch {
            return false
        }
    }

    public func lunarIsoFormat() -> String? {
        guard let l = currentLunar else { return nil }
        return String(format: "%04d-%02d-%02d%@", l.year, l.month, l.day, l.isLeapMonth ? " Intercalation" : "")
    }

    public func solarIsoFormat() -> String? {
        guard let s = currentSolar else { return nil }
        return String(format: "%04d-%02d-%02d", s.year, s.month, s.day)
    }

    // TODO: 간지 문자열 (추후 구현)
    public func getGapJaString() -> String? { return nil }
    public func getChineseGapJaString() -> String? { return nil }
}