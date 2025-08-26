# KoreanLunarCalendarSwift

[KoreanLunarCalendar](https://github.com/usingsky/KoreanLunarCalendar)를 Swift로 포팅한 프로젝트로, Apple 디바이스에서 한국 음력 달력을 사용할 수 있게 해주는 라이브러리입니다.

## 개요

KoreanLunarCalendarSwift는 한국천문연구원(KARI) 표준을 따라 양력과 음력 간의 정확한 변환 기능을 제공하는 Swift Package Manager 라이브러리입니다. ~~원본 Java 버전의 모든 기능을 Apple 플랫폼에서 사용할 수 있도록 포팅했습니다.~~ (아직 작업 중...)

### 주요 특징

- **한국천문연구원(KARI) 표준 기반**
- **1000년부터 2050년까지 지원**
- **음력 윤달(intercalation) 완벽 지원**
- **iOS, macOS, tvOS, watchOS 네이티브 지원**

## 지원 플랫폼

- iOS 13.0+
- macOS 12.0+
- tvOS 13.0+
- watchOS 6.0+

## 설치

### Swift Package Manager

Package.swift 파일에 다음을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/KoreanLunarCalendarSwift.git", from: "1.0.0")
]
```

또는 Xcode에서:

1. File → Add Package Dependencies...
2. 저장소 URL 입력
3. Add Package 클릭

## 지원 날짜 범위

- **음력**: 1000년 1월 1일 ~ 2050년 11월 18일
- **양력**: 1000년 2월 13일 ~ 2050년 12월 31일

## 사용법

### 기본 사용

```swift
import KoreanLunarCalendar

let calendar = KoreanLunarCalendar()

// 양력 -> 음력 변환
calendar.setSolarDate(2024, 1, 1)
print(calendar.lunarIsoFormat()) // 음력 날짜 출력
print(calendar.getGapJaString()) // 간지 출력

// 음력 -> 양력 변환 (윤달 여부 포함)
calendar.setLunarDate(2023, 12, 20, false) // 평달
print(calendar.solarIsoFormat()) // "2024-01-31"

// 음력 윤달 처리
calendar.setLunarDate(2023, 3, 15, true) // 윤3월
print(calendar.lunarIsoFormat()) // "2023-03-15 Intercalation"
print(calendar.solarIsoFormat()) // 해당 양력 날짜
```

### 원본 프로젝트와 동일한 API

이 Swift 포팅 버전은 원본 [KoreanLunarCalendar](https://github.com/usingsky/KoreanLunarCalendar)와 동일한 메서드명과 기능을 제공합니다:

```swift
calendar.setSolarDate(2017, 6, 24)
calendar.getLunarIsoFormat()
calendar.getGapjaString()

calendar.setLunarDate(1956, 1, 21, false)
calendar.getSolarIsoFormat()
```

### 데이터 구조

#### SolarDate

양력 날짜를 나타내는 구조체입니다.

```swift
public struct SolarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
}
```

#### LunarDate

음력 날짜를 나타내는 구조체입니다.

```swift
public struct LunarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool // 윤달 여부
}
```

## API 참조

### KoreanLunarCalendar

#### 메서드

- `setSolarDate(_:_:_:) -> Bool`: 양력 날짜를 설정하고 음력으로 변환
- `setLunarDate(_:_:_:_:) -> Bool`: 음력 날짜를 설정하고 양력으로 변환
- `solarIsoFormat() -> String?`: 현재 양력 날짜를 ISO 형식 문자열로 반환
- `lunarIsoFormat() -> String?`: 현재 음력 날짜를 ISO 형식 문자열로 반환
- `getGapJaString() -> String?`: 간지 문자열 반환 (구현 예정)
- `getChineseGapJaString() -> String?`: 한자 간지 문자열 반환 (구현 예정)

## 포팅 상태

원본 KoreanLunarCalendar 프로젝트를 Swift로 포팅하는 진행 상황:

- [x] 기본 구조 및 Swift 인터페이스 설계
- [x] Apple 플랫폼 패키지 구성 (SPM)
- [ ] 원본 Java 알고리즘을 Swift로 변환
- [ ] 음력-양력 변환 로직 구현
- [ ] 간지(干支) 계산 기능 구현
- [ ] 음력 데이터 테이블 포팅
- [ ] 날짜 범위 검증 로직
- [ ] 단위 테스트 완성

## 원본 프로젝트

이 프로젝트는 [usingsky/KoreanLunarCalendar](https://github.com/usingsky/KoreanLunarCalendar)를 기반으로 합니다. 원본 프로젝트의 타 언어용 라이브러리는 다음과 같습니다:

- **Java** (원본): [KoreanLunarCalendar](https://github.com/usingsky/KoreanLunarCalendar)
- **Python**: [Korean-Lunar-Calendar-py](https://github.com/usingsky/Korean-Lunar-Calendar-py)
- **JavaScript**: [korean-lunar-calendar-js](https://github.com/usingsky/korean-lunar-calendar-js)

## 테스트

```bash
swift test
```

## 라이센스

이 프로젝트는 원본 [KoreanLunarCalendar](https://github.com/usingsky/KoreanLunarCalendar)와 동일한 **MIT 라이센스** 하에 배포됩니다.

- **원본 프로젝트**: Copyright (c) 2016 usingsky
- **Swift 포팅**: 원본 라이센스 조건을 준수하며 포팅

자세한 내용은 `LICENSE` 파일을 참조하세요.
