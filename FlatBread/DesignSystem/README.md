# Design System

FlatBread 디자인 시스템은 토큰(Foundation)과 공통 컴포넌트(Components)를 중심으로 UI 일관성을 유지합니다.

## Foundation Tokens

- `FBColor`: 브랜드/텍스트/배경/보더/상태 컬러
- `FBTypography`: 화면에서 공통으로 사용하는 폰트 스타일
- `FBSpacing`: 간격 스케일
- `FBRadius`: 코너 라운드 스케일

## Components

- `FBButton`: 기본 액션 버튼 (`isLoading`, `isEnabled` 지원)
- `FBTextField`, `FBSecureField`: 입력 필드 (포커스/검증 상태 지원)

## Usage Rules

1. 새 UI는 인라인 스타일 대신 DS 토큰/컴포넌트를 우선 사용합니다.
2. 브랜드 컬러는 `Color("juhwang")` 직접 참조 대신 `FBColor.Brand.primary`를 사용합니다.
3. 버튼/입력 필드는 Feature 내부에서 중복 생성하지 않고 DS 컴포넌트를 재사용합니다.

## Migration Priority

1. `Auth` (완료: CTA + 입력 필드)
2. `CreateMoim`
3. `Profile`
4. `Home`
