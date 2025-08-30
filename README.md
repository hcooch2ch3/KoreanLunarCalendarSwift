# KoreanLunarCalendarSwift

한국 음력 달력을 위한 Swift 라이브러리입니다. Apple 디바이스에서 양력과 음력 간 정확한 변환과 간지(干支) 계산을 제공합니다.

## 개요

KoreanLunarCalendarSwift는 [한국천문연구원(KARI)](https://astro.kasi.re.kr/life/pageView/8) 표준을 따라 양력과 음력 간의 정확한 변환 기능을 제공하는 Swift Package Manager 라이브러리입니다. 원본 [KoreanLunarCalendar Java 라이브러리](https://github.com/usingsky/KoreanLunarCalendar)를 Swift로 포팅했습니다.

### 주요 특징

- **한국천문연구원(KARI) 표준 기반**
- **1000년부터 2050년까지 지원**
- **음력 윤달(intercalation) 완벽 지원**
- **간지(干支) 계산 기능 제공**
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

### 라이브러리 import

```swift
import KoreanLunarCalendar

// 기본 달력 인스턴스 생성
let calendar = KoreanLunarCalendar()

// 성능 최적화가 필요한 경우 (10배 빠름)
let fastCalendar = KoreanLunarCalendar(enableOptimization: true)
```

### 1. 양력 → 음력 변환

```swift
// 양력 날짜 설정
let success = calendar.setSolarDate(2024, 2, 10) // 2024년 2월 10일
if success {
    // 변환된 음력 날짜 확인
    if let lunar = calendar.lunarIsoFormat() {
        print("음력: \(lunar)")  // 출력: "2024-01-01" (음력 2024년 1월 1일)
    }

    // 간지 정보 확인
    if let gapja = calendar.getGapJaString() {
        print("간지: \(gapja)")  // 출력: "갑진년 을축월 갑자일"
    }
}
```

### 2. 음력 → 양력 변환

```swift
// 평달 (일반 월)
let success = calendar.setLunarDate(2024, 1, 15, false)
if success {
    if let solar = calendar.solarIsoFormat() {
        print("양력: \(solar)")  // 출력: "2024-02-24"
    }
}

// 윤달 (intercalation month)
calendar.setLunarDate(2020, 4, 15, true) // 2020년 윤4월 15일
if let solar = calendar.solarIsoFormat() {
    print("양력: \(solar)")  // 출력: "2020-06-06"
}
if let lunar = calendar.lunarIsoFormat() {
    print("음력: \(lunar)")  // 출력: "2020-04-15 Intercalation"
}
```

### 3. 간지(干支) 계산

```swift
// 양력 날짜로 간지 계산
calendar.setSolarDate(2024, 1, 1)

// 음력 기준 간지 (기본값)
if let korean = calendar.getGapJaString() {
    print("음력 간지: \(korean)")  // "계묘년 갑자월 갑자일" (음력 2023년 11월 20일 기준)
}

// 양력 기준 간지 
if let solarKorean = calendar.getGapJaString(isSolarGapja: true) {
    print("양력 간지: \(solarKorean)")  // "갑진년 병인월 갑자일" (양력 2024년 1월 1일 기준)
}

// 한자 간지 (음력/양력 선택 가능)
if let chinese = calendar.getChineseGapJaString() {
    print("음력 한자 간지: \(chinese)")  // "癸卯年 甲子月 甲子日"
}
if let solarChinese = calendar.getChineseGapJaString(isSolarGapja: true) {
    print("양력 한자 간지: \(solarChinese)")  // "甲辰年 丙寅月 甲子日"
}

// 윤달의 경우 (윤) 또는 (閏) 표시 (음력 간지에만 적용)
calendar.setLunarDate(2020, 4, 15, true) // 윤4월
if let gapja = calendar.getGapJaString() {
    print("윤달 간지: \(gapja)")  // "경자년 신사월 경진일(윤)"
}
```

### 4. 날짜 유효성 검사

```swift
// 유효한 날짜인지 확인
let isValid = calendar.setSolarDate(2024, 2, 29)  // true (윤년)
let isInvalid = calendar.setSolarDate(2023, 2, 29)  // false (평년)

// 윤달 유효성 검사
let validLeap = calendar.setLunarDate(2020, 4, 15, true)  // true (2020년 윤4월 존재)
let invalidLeap = calendar.setLunarDate(2019, 4, 15, true)  // false (2019년 윤4월 없음)
```

## 중요사항

- **날짜 변환**: 양력 날짜를 설정하면 자동으로 음력으로 변환되고, 음력 날짜를 설정하면 자동으로 양력으로 변환됩니다.
- **간지 계산**: 기본적으로 음력 날짜를 기준으로 계산되며, `isSolarGapja: true` 매개변수로 양력 기준 계산도 가능합니다.
- **윤달 처리**: 음력 날짜 설정 시 네 번째 매개변수로 윤달 여부를 지정해야 합니다.
- **날짜 범위**: 1000년~2050년 범위 밖의 날짜는 설정할 수 없습니다.
- **성능 최적화**: `enableOptimization: true`로 초기화하면 Lazy Lookup Table을 사용해 약 10배 빠른 성능을 제공합니다. (달력 UI 구현 등 여러번 호출해야할 경우 유리)

## 실제 사용 예시

### 한국 설날 간지 계산

```swift
let calendar = KoreanLunarCalendar()

// 2024년 설날 (양력 2024-02-10)
calendar.setSolarDate(2024, 2, 10)
print("양력: \(calendar.solarIsoFormat() ?? "")")     // "2024-02-10"
print("음력: \(calendar.lunarIsoFormat() ?? "")")     // "2024-01-01"
print("간지: \(calendar.getGapJaString() ?? "")")     // "갑진년 을축월 갑자일"
```

### 생일 변환 예시

```swift
// 음력 생일을 양력으로 변환
let calendar = KoreanLunarCalendar()

// 음력 1990년 3월 15일 생 (평달)
calendar.setLunarDate(1990, 3, 15, false)
if let solarBirthday = calendar.solarIsoFormat() {
    print("양력 생일: \(solarBirthday)")
}

// 올해 음력 생일이 양력 몇 월 며칠인지 확인
calendar.setLunarDate(2024, 3, 15, false)
if let thisYearBirthday = calendar.solarIsoFormat() {
    print("2024년 음력 생일: \(thisYearBirthday)")
}
```

## API 참조

### KoreanLunarCalendar 클래스

#### 초기화

```swift
// 기본 초기화 (메모리 효율적)
init()

// 성능 최적화 초기화 (약 10배 빠름)
init(enableOptimization: Bool)
```

#### 날짜 설정 메서드

```swift
// 양력 날짜 설정 및 음력 변환
func setSolarDate(_ year: Int, _ month: Int, _ day: Int) -> Bool

// 음력 날짜 설정 및 양력 변환
func setLunarDate(_ year: Int, _ month: Int, _ day: Int, _ intercalation: Bool) -> Bool
```

#### 날짜 조회 메서드

```swift
// 현재 양력 날짜를 "YYYY-MM-DD" 형식으로 반환
func solarIsoFormat() -> String?

// 현재 음력 날짜를 "YYYY-MM-DD" 또는 "YYYY-MM-DD Intercalation" 형식으로 반환
func lunarIsoFormat() -> String?
```

#### 간지 계산 메서드

```swift
// 한글 간지 반환 ("갑자년 을축월 병인일")
// isSolarGapja: true면 양력 기준, false면 음력 기준 (기본값: false)
func getGapJaString(isSolarGapja: Bool = false) -> String?

// 한자 간지 반환 ("甲子年 乙丑月 丙寅日")
// isSolarGapja: true면 양력 기준, false면 음력 기준 (기본값: false)
func getChineseGapJaString(isSolarGapja: Bool = false) -> String?
```

#### 날짜 구조체 접근

```swift
// 현재 설정된 양력 날짜
var currentSolar: SolarDate? { get }

// 현재 설정된 음력 날짜
var currentLunar: LunarDate? { get }
```

### 데이터 구조

#### SolarDate

```swift
public struct SolarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
}
```

#### LunarDate

```swift
public struct LunarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool // 윤달 여부
}
```

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

## 성능 최적화

### 기본 사용 vs 최적화 사용

```swift
// 기본 사용 (메모리 사용량 최소)
let calendar = KoreanLunarCalendar()

// 성능 최적화 사용 (10배 빠름, 약간의 메모리 사용)
let fastCalendar = KoreanLunarCalendar(enableOptimization: true)
```

### 언제 최적화를 사용할까요?

**최적화 권장 상황:**

- 많은 날짜 변환을 연속으로 수행하는 경우
- 사용자 인터페이스에서 실시간 변환이 필요한 경우
- 대량의 날짜 데이터를 처리하는 경우

**최적화 불필요 상황:**

- 가끔씩 한두 번의 변환만 하는 경우
- 메모리 사용량을 최소화해야 하는 경우

### 최적화 사용시 성능 개선 효과

벤치마크 테스트 결과 (800회 변환 기준):

- 일반 모드: ~4.4초
- 최적화 모드: ~0.4초
- **성능 향상: 약 10배**

### 최적화 사용시 메모리 사용량

최적화 모드에서 사용되는 추가 메모리:

- 연도별 누적 일수 캐시: ~4KB (1000년-2050년)
- 월별 일수 캐시: ~2KB (자주 사용되는 월 데이터)
- **총 추가 로드되는 메모리: 약 6KB**

## 개발 시 디버그 로깅

개발 중에만 내부 로그를 보려면 환경변수를 설정하세요:

```bash
# 디버그 로그 활성화
KLC_DEV=1 swift run
KLC_DEV=1 swift test

# 일반 실행 (로그 없음)
swift run
```

## 포팅 상태

원본 KoreanLunarCalendar 프로젝트를 Swift로 포팅하는 진행 상황:

- [x] 기본 구조 및 Swift 인터페이스 설계
- [x] Apple 플랫폼 패키지 구성 (SPM)
- [x] 음력 데이터 테이블 포팅 (lunar_table.json)
- [x] 원본 Java 알고리즘을 Swift로 변환
- [x] 음력-양력 변환 로직 구현
- [x] 간지(干支) 계산 기능 구현
- [x] 날짜 범위 검증 로직
- [x] 단위 테스트 완성

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
