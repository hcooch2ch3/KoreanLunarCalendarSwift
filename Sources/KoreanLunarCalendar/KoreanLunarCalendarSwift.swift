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

struct LunarTableMetadata: Codable {
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
            let yearData = try DataLoader.shared.getData(for: year)
            
            // 임시로 데이터 로드 성공 확인
            self.currentSolar = SolarDate(year: year, month: month, day: day)
            
            // 비트 연산으로 정보 추출 (임시 테스트)
            let intercalationMonth = (yearData >> 12) & 0xF
            let totalDays = (yearData >> 17) & 0x1FF
            let isLeapYear = (yearData >> 30) & 0x1 == 1
            
            print("Year \(year): intercalation=\(intercalationMonth), totalDays=\(totalDays), isLeapYear=\(isLeapYear)")
            
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
            let yearData = try DataLoader.shared.getData(for: year)
            
            // 임시로 데이터 로드 성공 확인
            self.currentLunar = LunarDate(year: year, month: month, day: day, isLeapMonth: intercalation)
            
            // 비트 연산으로 정보 추출 (임시 테스트)
            let intercalationMonth = (yearData >> 12) & 0xF
            let totalDays = (yearData >> 17) & 0x1FF
            let isLeapYear = (yearData >> 30) & 0x1 == 1
            
            print("Year \(year): intercalation=\(intercalationMonth), totalDays=\(totalDays), isLeapYear=\(isLeapYear)")
            
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