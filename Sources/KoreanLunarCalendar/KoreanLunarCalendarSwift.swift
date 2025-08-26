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

enum DataLoaderError: Error { case resourceNotFound, decodeFailed }

final class DataLoader {
    static let shared = DataLoader()
    private(set) var isLoaded = false

    // TODO: 추후 실제 구조로 바꿀 예정
    private(set) var table: [String: Int] = [:]

    private init() {}

    func loadIfNeeded() throws {
        guard !isLoaded else { return }
        guard let url = Bundle.module.url(forResource: "lunar_table", withExtension: "json") else {
            throw DataLoaderError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        // TODO: 우선 더미 파싱(실제 테이블 구조 정하면 Codable로 교체)
        if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Int] {
            self.table = obj
            self.isLoaded = true
        } else {
            throw DataLoaderError.decodeFailed
        }
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
            // TODO: 변환 알고리즘 구현 (테이블 기반)
            // 임시 스텁:
            self.currentSolar = SolarDate(year: year, month: month, day: day)
            // 변환 결과를 임시로 nil 처리. 구현 후 실제 값 세팅
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
            // TODO: 변환 알고리즘 구현
            self.currentLunar = LunarDate(year: year, month: month, day: day, isLeapMonth: intercalation)
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