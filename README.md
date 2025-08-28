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
    .package(url: "https://github.com/hcooch2ch3/KoreanLunarCalendarSwift.git", from: "1.0.0")
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
if let lunar = calendar.lunarIsoFormat() {
    print("음력: \(lunar)")
}
if let gapja = calendar.getGapJaString() {
    print("간지: \(gapja)")
}

// 음력 -> 양력 변환 (윤달 여부 포함)
calendar.setLunarDate(2023, 12, 20, false) // 평달
if let solar = calendar.solarIsoFormat() {
    print("양력: \(solar)") // "2024-01-31"
}

// 음력 윤달 처리
calendar.setLunarDate(2023, 3, 15, true) // 윤3월
if let lunar = calendar.lunarIsoFormat() {
    print("음력: \(lunar)") // "2023-03-15 Intercalation"
}
if let solar = calendar.solarIsoFormat() {
    print("양력: \(solar)") // 해당 양력 날짜
}
```

### 개발 시 디버그 로깅

개발 중에만 내부 로그를 보려면 환경변수를 설정하세요:

```bash
# 디버그 로그 활성화
KLC_DEV=1 swift run
KLC_DEV=1 swift test

# 일반 실행 (로그 없음)
swift run
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

## 데이터 구조

### lunar_table.json

이 프로젝트는 한국천문연구원(KARI) 표준을 기반으로 한 1000-2050년의 음력 데이터를 사용합니다.

#### 데이터 배열 구조

`data` 배열의 각 정수는 **한 해의 음력 정보를 32비트로 압축 인코딩**한 값입니다:

```
배열 순서:
- data[0] = 1000년 데이터
- data[1] = 1001년 데이터  
- data[1050] = 2050년 데이터
```

#### 비트 인코딩 구조

각 32비트 정수의 비트 구성:
```
[태양력윤년(1비트)][총음력일수(9비트)][윤달월(4비트)][월패턴(12비트)]
```

- **월 패턴** (0-11비트): 각 월의 큰달(30일)/작은달(29일) 정보
- **윤달월** (12-15비트): 윤달이 있는 월 (0이면 평년)
- **총 음력일수** (17-25비트): 해당 연도의 총 음력 일수
- **태양력 윤년** (30비트): 해당 태양력 연도의 윤년 여부

#### Swift에서 비트 추출

```swift
let yearData = data[year - 1000]  // 1000년 기준 인덱스

// 윤달월 추출
let intercalationMonth = (yearData >> 12) & 0xF

// 총 음력일수 추출
let totalDays = (yearData >> 17) & 0x1FF

// 태양력 윤년 여부
let isLeapYear = (yearData >> 30) & 0x1 == 1

// 특정 월의 일수 (1-12월)
let monthDays = ((yearData >> (12 - month)) & 0x1) == 1 ? 30 : 29
```

#### 예시

`2194016855` (1000년 데이터):
- 이진수: `10000010100100000000100001010111`
- 월 패턴: `000100001010111` → 1,4,6,8,10,12월이 큰달(30일)
- 윤달월: `0000` → 윤달 없음
- 총일수: `101001000` → 354일
- 태양력 윤년: `1` → 윤년

## 포팅 상태

원본 KoreanLunarCalendar 프로젝트를 Swift로 포팅하는 진행 상황:

- [x] 기본 구조 및 Swift 인터페이스 설계
- [x] Apple 플랫폼 패키지 구성 (SPM)
- [x] 음력 데이터 테이블 포팅 (lunar_table.json)
- [ ] 원본 Java 알고리즘을 Swift로 변환
- [ ] 음력-양력 변환 로직 구현
- [ ] 간지(干支) 계산 기능 구현
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
