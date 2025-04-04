# Try On Hanbok - 한복 가상 피팅 프로젝트

Flutter로 개발된 한복 가상 피팅 웹 애플리케이션입니다.

## 기능

- 사용자 이미지 업로드
- 한복 디자인 선택 (모던/전통)
- AI 기반 가상 피팅
- 결과 이미지 다운로드 및 공유
- 진행 상태 표시 (프로그레스 바)

## 개발 환경 설정

1. Flutter SDK 설치 (버전 3.7 이상)
2. 저장소 클론
   ```
   git clone https://github.com/your-username/try-on-hanbok.git
   cd try-on-hanbok
   ```
3. 의존성 패키지 설치
   ```
   flutter pub get
   ```
4. 웹 애플리케이션 실행
   ```
   flutter run -d chrome
   ```

## 프로젝트 구조

```
lib/
  |- constants/       # 앱 상수 (디자인, 색상, 테마)
  |- pages/           # 페이지 위젯
  |- widgets/         # 재사용 가능한 UI 위젯
  |- main.dart        # 앱 진입점
supabase_services/    # 백엔드 연동 서비스
```

## 커스텀 린트 규칙

이 프로젝트는 다음과 같은 커스텀 린트 규칙을 사용합니다:

- **한국어 주석** 허용
- **print 문** 사용 허용
- **작은 따옴표** 사용 권장
- **웹 라이브러리** 사용 허용 (크로스플랫폼 지원용)

자세한 린트 규칙은 다음 파일에서 확인할 수 있습니다:
- `analysis_options.yaml` - 린트 규칙 설정
- `lib/lint_rules.txt` - 린트 규칙 설명 및 사용법

## 린트 검사 및 자동 수정

```bash
# 린트 규칙 검사
flutter analyze

# 자동 수정 가능한 린트 문제 해결
dart fix --apply
```

## 백엔드 서비스

이 애플리케이션은 Supabase와 Edge Functions를 사용하여 다음과 같은 기능을 제공합니다:

- 이미지 저장 및 관리
- AI 모델 연동 (한복 가상 피팅)
- 익명 사용자 인증

## 기여하기

1. Fork 저장소
2. 기능 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'Add some amazing feature'`)
4. 브랜치에 푸시 (`git push origin feature/amazing-feature`)
5. Pull Request 생성
