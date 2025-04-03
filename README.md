# test02 프로젝트 문서화


## 1. 디렉토리 구조와 각 폴더의 역할

```
test02/
├── lib/
│   ├── constants/       # 상수, 테마, 스타일 정의
│   │   ├── app_colors.dart     # 색상 상수
│   │   ├── app_constants.dart  # 앱 전반의 상수 값
│   │   ├── app_responsive.dart # 반응형 디자인 브레이크포인트
│   │   ├── app_sizes.dart      # 크기/패딩 관련 상수
│   │   ├── app_text_styles.dart # 텍스트 스타일 상수
│   │   ├── app_theme.dart      # 앱 테마 정의
│   │   └── exports.dart        # 상수 파일들을 한번에 내보내기
│   ├── pages/          # 페이지 단위 위젯 (전체 화면)
│   │   ├── generate_page.dart  # 한복 생성 페이지
│   │   ├── home_page.dart      # 홈 페이지
│   │   └── result_page.dart    # 결과 페이지
│   ├── widgets/        # 재사용 가능한 위젯 구성요소
│   │   ├── best_section.dart   # 홈 페이지의 추천 한복 섹션 (select_section 의 확장)
│   │   ├── generate_section.dart # 한복 생성을 위한 섹션
│   │   ├── header.dart         # 헤더 위젯
│   │   ├── home_section.dart   # 홈 페이지 메인 섹션
│   │   ├── result_section.dart # 결과 표시 섹션
│   │   ├── select_section.dart # 한복 선택 섹션
│   │   └── tutorial_section.dart # 튜토리얼 섹션
│   └── main.dart       # 앱 진입점
├── assets/            # 이미지, 폰트 등 리소스 파일
│   └── images/        # 이미지 폴더
│       ├── modern/    # 모던 한복 이미지
│       ├── traditional/ # 전통 한복 이미지
│       └── lang/       # 언어 아이콘 이미지
└── pubspec.yaml      # 프로젝트 메타데이터 및 종속성
```


## 2. 프로젝트 구조 설명

이 프로젝트는 Flutter로 개발된 반응형 웹 애플리케이션으로, 페이지와 섹션의 역할을 명확히 분리하여 관리합니다. 각 페이지는 섹션들을 포함하며, 섹션은 독립적으로 기능하고 약간의 상호작용을 수행합니다.


## 3. 페이지와 섹션의 역할 정의

-페이지 (Pages)

역할: 전체 화면 단위로 UI를 구성하며, 섹션들을 포함하여 화면을 렌더링합니다.

특징: 페이지는 UI 배치를 담당하며, 직접적인 기능 구현은 하지 않습니다.
     각 페이지는 필요한 섹션을 호출하고 배치만 수행합니다.

예시: home_page.dart: header.dart, home_section.dart, best_section.dart 섹션을 포함하여 홈 화면을 구성.
     generate_page.dart: generate_section.dart, select_section.dart를 포함하여 한복 생성 화면을 구성.

-섹션 (Sections)

역할: 특정 기능을 독립적으로 수행하며, 재사용 가능한 위젯으로 설계됩니다.

특징: 각 섹션은 독립적으로 동작하며, 필요한 기능을 자체적으로 구현합니다.
     다른 섹션과 약간의 상호작용(데이터 전달 등)을 할 수 있습니다.

예시: generate_section.dart: 한복 생성 로직과 UI를 포함.
     result_section.dart: 생성된 결과를 표시하는 UI와 데이터를 렌더링.


## 4. 작업 규칙 및 참고 사항

-규칙

페이지는 섹션을 호출하고 배치만 수행 : 페이지에서 직접적인 비즈니스 로직이나 데이터 처리 작업은 하지 않습니다.
                                  모든 기능은 섹션 내부에서 구현됩니다.

섹션은 독립적으로 설계: 각 섹션은 재사용성을 고려해 설계되며, 다른 페이지에서도 쉽게 호출 가능해야 합니다.
                     섹션 간 상호작용이 필요한 경우, 명시적으로 데이터를 전달하거나 상태 관리를 사용합니다.

상호작용 최소화: 섹션 간 데이터 전달은 필요할 경우에만 수행하며, 복잡한 의존성을 만들지 않습니다.

* Cursor가 작업할 때 다음 사항을 준수해야 합니다:
1. 페이지는 레이아웃 배치만 담당하며, 기능 구현은 하지 않습니다.
2. 각 섹션은 독립적으로 동작해야 하며, 다른 섹션에 의존하지 않도록 설계합니다.
3. 기존 구조를 유지하면서 요청된 수정 사항만 반영하세요.
4. 문서화된 규칙과 역할 정의를 기반으로 작업하세요.
5. 모든 코드 수정 요청 시 관련된 문서를 업데이트합니다.
6. 문서 수정 시 기존 내용을 유지하며, 새로운 내용을 추가하는 방식으로 작업합니다.

## Restrictions
- 기존 구조를 변경하지 않고, 요청된 수정 사항만 반영합니다.
- 불필요한 설명이나 중복된 내용은 추가하지 않습니다.


## 5. 주요 클래스 및 함수 설명

### constants/

**app_colors.dart**
- `AppColors`: 앱에서 사용하는 모든 색상 정의
  - `primary`, `background`, `textPrimary` 등 색상 상수 제공
  - 디자인 일관성 유지와 테마 변경 용이성을 위해 사용

**app_responsive.dart**
- `AppResponsive`: 반응형 디자인을 위한, 다양한 기기 크기에 따른 브레이크포인트 정의
  - 모바일, 태블릿, 데스크톱 기기 너비 정의
  - 미디어 쿼리를 간소화하여 반응형 UI 구현 지원

**app_sizes.dart**
- `AppSizes`: 앱 내 사이즈와 패딩 관련 상수 정의
  - 기기 크기에 따른 UI 요소의 적절한 크기 반환 함수 제공
  - `getScreenPadding`, `getButtonWidth` 등 기기별 최적화된 크기 제공

**app_text_styles.dart**
- `AppTextStyles`: 앱 내 모든 텍스트 스타일 정의
  - 일관된 텍스트 스타일링 제공
  - 기기 크기별 텍스트 크기 최적화


### pages/

**home_page.dart**
- `HomePage`: 앱 메인 페이지
  - `HomeSection`, `BestSection`, `TutorialSection` 포함
  - 사용자에게 앱 소개 및 주요 기능 제공

**generate_page.dart**
- `GeneratePage`: 한복 시착 이미지 생성 페이지
  - 사용자 이미지와 한복 선택 인터페이스 제공
  - `GenerateSection`과 `SelectSection` 포함

**result_page.dart**
- `ResultPage`: 한복 시착 결과 페이지
  - 생성된 이미지 표시
  - `ResultSection` 포함

### widgets/

**header.dart**
- `Header`: 앱 상단바
  - 로고 및 네비게이션 버튼 제공

**best_section.dart**
- `BestSection`: 인기 한복 모음 섹션
  - `SelectSection`의 확장으로, 필터 버튼을 숨기고 주요 한복 표시
  - 홈 화면에서 사용자를 `GeneratePage`로 유도

**tutorial_section.dart**
- `TutorialSection`: 앱 사용 방법 튜토리얼 제공
  - 단계별 사용 안내 표시 (3단계 과정)
  - 반응형 레이아웃 (모바일/데스크톱)
  - "Try On Hanbok" 버튼으로 사용자를 생성 페이지로 유도
  - 시각적 아이콘과 설명으로 앱 사용법 소개


**generate_section.dart**
- `GenerateSection`: 이미지 업로드 및 한복 선택 인터페이스
  - 사용자 이미지 업로드 기능
  - 한복 프리셋 선택 기능
  - Try On 버튼으로 결과 페이지로 이동

**select_section.dart**
- `SelectSection`: 한복 선택 그리드 제공
  - 모던/트래디셔널 필터링 기능
  - 그리드 형태로 한복 이미지 표시
  - 이미지 호버 및 선택 효과
  - 스크롤 컨트롤러를 통한 페이지 상단 이동 기능


**result_section.dart**
- `ResultSection`: 결과 이미지 표시 섹션
  - 생성된 이미지 또는 로딩 인디케이터 표시


### 주요 함수

**generate_section.dart**
- `_pickImage()`: 사용자의 갤러리에서 이미지 선택
- `_onImageSelected()`: 한복 이미지 선택 시 상태 업데이트 및 스크롤
- `_scrollToTop()`: 페이지 상단으로 스크롤

**select_section.dart**
- `getFilteredImages()`: 선택된 필터에 따라 이미지 필터링
- `_buildImageGridSection()`: 이미지 그리드 구성
- `_scrollToTop()`: 페이지 상단으로 스크롤 이동

**tutorial_section.dart**
- `_buildTutorialStep()`: 튜토리얼 단계 UI 생성
- `_buildActionButton()`: 한복 시착 버튼 생성

**result_section.dart**
- `_saveImage()`: 결과 이미지 저장 기능 (웹/모바일 환경 구분 처리)
- `_shareImage()`: 결과 이미지 공유 기능 (웹/모바일 환경 구분 처리)
- `_navigateToGenerate()`: 다시 시도하기 기능 (생성 페이지로 이동)
- `_captureImage()`: 화면 내 이미지 영역을 캡처하는 기능 *이미지파일 자체를 저장하게끔 수정예정*
- `_downloadImageForWeb()`: 웹 환경에서 이미지 다운로드 처리
- `_buildActionButton()`: 액션 버튼 UI 생성 (다운로드, 공유, 다시 시도하기)


## 3. 상태 관리 도구 및 데이터 흐름

### 상태 관리
- **StatefulWidget 기반 로컬 상태 관리**:
  - 각 위젯이 자체적으로 상태를 관리하는 방식 사용
  - `GenerateSection`, `SelectSection` 등에서 `setState()`를 통한 상태 업데이트

### 데이터 흐름
1. **콜백 함수 방식**:
   - 자식 위젯에서 발생한 이벤트를 부모 위젯에 전달하기 위해 콜백 함수 사용
   - 예: `SelectSection`의 `onImageClick`, `onFilterChange` 콜백

2. **상태 전달**:
   - 부모에서 자식으로 상태를 전달하여 UI 업데이트
   - 예: `GeneratePage`에서 `GenerateSection`으로 `selectedHanbok` 전달

3. **페이지 간 데이터 전달**:
   - `Navigator.pushNamed()`의 `arguments` 매개변수를 통해 페이지 간 데이터 전달
   - 예: 선택된 한복 이미지 정보를 `GeneratePage`에서 `ResultPage`로 전달

## 4. UI 구성 요소

### 테마 및 색상
- `app_colors.dart`에서 정의된 일관된 색상 팔레트 사용
  - `primary`: 주 색상 (퍼플)
  - `secondary`: 보조 색상 (청록)
  - `accent`: 강조 색상 (노랑)
  - `background`: 배경 색상
  - `textPrimary`, `textSecondary`: 텍스트 색상

### 반응형 레이아웃
- `AppResponsive` 및 `AppSizes` 클래스를 통한 반응형 디자인 구현
  - 모바일, 태블릿, 데스크톱 각 화면 크기에 맞는 레이아웃 제공
  - 기기 타입별 최적화된 패딩, 버튼 크기, 폰트 크기 등 제공

### 주요 UI 컴포넌트
- **버튼**: 둥근 모서리, 일관된 크기와 스타일
- **카드**: 둥근 모서리로 시각적 계층 제공
- **이미지 그리드**: `MasonryGridView` 사용 다양한 크기의 이미지 배치
- **애니메이션**: `AnimatedContainer` 등을 활용한 부드러운 UI 전환 효과

## 5. API 호출 및 외부 서비스 연동 방식

현재 프로젝트에서는 직접적인 API 호출이나 외부 서비스 연동이 구현되어 있지 않습니다. 향후 API 연동 시 다음 방식을 고려할 수 있습니다:

### 계획된 구현 방향
1. **한복 시착 AI 서비스 연동**:
   - `http` 패키지를 사용한 REST API 호출
   - 사용자 이미지와 선택한 한복 이미지를 서버로 전송
   - 생성된 결과 이미지를 받아 `ResultPage`에 표시

2. **이미지 처리**:
   - `image_picker` 패키지 사용하여 사용자 이미지 선택 (현재 구현됨)
   - `dio` 패키지를 활용한 이미지 업로드 구현

3. **인증 및 사용자 관리**:
   - 향후 Firebase Authentication 또는 자체 백엔드 서비스 연동 가능

### 현재 사용 중인 외부 패키지
- `image_picker`: 사용자 이미지 선택
- `flutter_staggered_grid_view`: 불규칙한 그리드 레이아웃 구현
- `responsive_framework`: 반응형 UI 지원

이 프로젝트는 현재 한복 시착 앱의 프론트엔드 UI를 중점적으로 구현하고 있으며, 백엔드 연동은 향후 개발 단계에서 추가될 예정입니다. 
