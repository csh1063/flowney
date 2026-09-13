# Flowney

여행 중 데이터가 거의 없어도 동작하는 걸 목표로 만든 개인용 여행 일정/경로 앱.
날짜별 일정을 지도 위에서 관리하고, 장소 간 실제 이동 경로(도보/대중교통/자동차)를
탐색해서 정류장 이동 애니메이션으로 보여준다.

## 주요 기능

- **일정 관리**: 여행 생성 시 나라 선택 → 날짜별 일정 추가/삭제/순서변경/드래그 이동.
  구글맵 공유 링크(공유 확장 포함) 또는 수동 입력으로 장소 등록.
- **지도 중심 화면**: 하루 동선을 지도 위에 표시하고, 리스트에서 장소를 탭하면 그
  장소로 이동하는 애니메이션이 재생된다(이전/다음 버튼으로 정류장 단위 이동도 가능).
- **경로 탐색**: 인접한 장소 사이 실제 경로(도보/대중교통/자동차)를 자동으로 비교해서
  더 나은 수단을 추천 — 대중교통이 도보보다 확실히 빠를 때만 추천하고, 걷는 시간이
  이미 길면 약간의 시간 차이만 나도 대중교통을 추천한다. 대중교통 노선은 실제 브랜드
  색(구글 GTFS 데이터 기준)으로, 없으면 이동수단별 기본색으로 표시하고 환승 지점에는
  작은 점 마커를 찍는다.
- **온디바이스 경로 캐시**: 한 번 탐색한 구간은 SwiftData로 기기에 저장해서, 다시
  열 때는 오프라인에서도 그대로 표시되고 네트워크를 다시 태우지 않는다.
- **국가 경계 표시**: 일정 항목의 좌표를 리버스 지오코딩해서 국가코드를 계산하고(한
  번 계산되면 DB에 저장돼 재사용), 하루에 여러 나라를 걸치면 날짜 헤더를 나라 수만큼
  균등 분할해서 표시한다. 여행에 등록되지 않은 나라 좌표는 경고 아이콘으로 표시.
- **날씨**: 날짜별 대표 좌표 기준으로 예보를 가져와 날짜 탭에 아이콘으로 표시.
- **예산**: 여행 항목별 비용/통화/결제상태 기록.
- **로그인**: Apple / Google 로그인.

## 아키텍처

[Tuist](https://tuist.io)로 관리하는 멀티 모듈 iOS 프로젝트. UI는 SwiftUI, 상태 관리는
[The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)(TCA) 사용.

```
Flowney (App)
├── ShareExtension        # 구글맵 공유 링크를 앱으로 넘기는 Share Extension
├── Features/
│   ├── Root               # 로그인 여부에 따라 최상위 화면 분기
│   ├── Auth                # Apple/Google 로그인
│   ├── TripList            # 여행 목록
│   ├── TripEdit             # 여행 생성/수정(나라 선택 등)
│   ├── Itinerary            # 지도+일정 메인 화면(경로 탐색/애니메이션 포함)
│   ├── AddItem              # 일정 항목 추가(링크 파싱/수동 입력)
│   └── Budget                # 예산 관리
└── Core/
    ├── Models              # Trip/TripDay/ItineraryItem/RouteLeg 등 공용 모델
    ├── APIClient            # Supabase 리포지토리 + 백엔드 API 클라이언트(TCA @DependencyClient)
    └── DesignSystem         # 공용 색상/스타일 헬퍼
```

각 모듈은 독립된 `Project.swift`를 갖는 정적 프레임워크이며, `Workspace.swift`가 전체를
하나의 Xcode 워크스페이스로 묶는다.

## 기술 스택

- SwiftUI + TCA 1.26.1
- Google Maps SDK(iOS) — 지도, 폴리라인, 마커 애니메이션
- Supabase — Postgres(여행/일정/경로 캐시 데이터), Auth, PostgREST
- SwiftData — 경로 탐색 결과 온디바이스 캐시(iOS 17+)
- 백엔드: [mock-serverless](../mock-serverless)(별도 저장소) — Vercel 서버리스 함수로
  Google Directions/Places/Weather API를 프록시하고 결과를 캐싱(`route_cache` 테이블)

## 요구사항

- Xcode 26 이상, iOS 17.2+
- [Tuist](https://docs.tuist.io) 설치
- Apple Developer 계정(실기기 빌드용 서명)

## 시작하기

```bash
git clone <this repo>
cd Flowney
tuist install    # SwiftPM 의존성 설치
tuist generate   # .xcworkspace 생성
```

`Projects/App/Config.xcconfig.example`을 `Config.xcconfig`로 복사하고 값을 채운다(이
파일은 `.gitignore`에 포함되어 있음):

```
GOOGLE_IOS_CLIENT_ID       # Google Cloud Console의 iOS OAuth 클라이언트
GOOGLE_REVERSED_CLIENT_ID  # 위 클라이언트 ID를 뒤집은 URL Scheme
GOOGLE_MAPS_API_KEY        # iOS 앱 제한을 건 Maps SDK 전용 키
SUPABASE_HOST              # "https://" 없이 호스트만 (예: xxxx.supabase.co)
SUPABASE_ANON_KEY          # Supabase anon(공개) 키
```

`Tuist/ProjectDescriptionHelpers/Constants.swift`의 `developmentTeam` 값을 본인의
Apple Developer 팀 ID로 바꾼다(실기기 서명용).

Supabase 프로젝트에는 `mock-serverless/supabase/migrations`의 SQL을 순서대로 적용한다.

## 실행

```bash
xcodebuild -workspace Flowney.xcworkspace -scheme Flowney \
  -destination 'generic/platform=iOS Simulator' build
```

또는 `Flowney.xcworkspace`를 Xcode로 열어서 실행.
