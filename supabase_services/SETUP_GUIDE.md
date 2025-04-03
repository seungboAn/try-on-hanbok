# Supabase Services 설정 가이드

이 가이드는 Hanbok Virtual Fitting 애플리케이션의 Supabase 로직을 새로운 Flutter 프로젝트에서 재사용하기 위한 단계별 지침을 제공합니다.

## 1. 새 Flutter 프로젝트 생성

새 Flutter 프로젝트를 생성합니다:

```bash
# 새 프로젝트 생성
flutter create my_new_project

# 새 프로젝트 디렉토리로 이동
cd my_new_project
```

## 2. Supabase Services 패키지 설정

두 가지 방법으로 패키지를 설정할 수 있습니다:

### 방법 1: 자동 설정 스크립트 사용 (권장)

생성된 `setup_script.sh` 스크립트를 사용하여 자동으로 설정합니다:

```bash
# setup_script.sh 경로를 자신의 환경에 맞게 조정하세요
/path/to/supabase_services/setup_script.sh /path/to/my_new_project
```

이 스크립트는 다음 작업을 수행합니다:
- 서비스 패키지를 새 프로젝트에 복사
- `.env` 파일 생성
- 프로젝트의 `pubspec.yaml` 업데이트
- 예제 코드 생성
- `main.dart` 파일에 Supabase 초기화 코드 추가

### 방법 2: 수동 설정

1. 서비스 패키지를 새 프로젝트로 복사:
   ```bash
   mkdir -p /path/to/my_new_project/supabase_services
   cp -r /path/to/supabase_services/* /path/to/my_new_project/supabase_services/
   ```

2. `.env` 파일 생성:
   ```bash
   cp /path/to/supabase_services/.env.example /path/to/my_new_project/.env
   ```

3. `pubspec.yaml` 파일 수정:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     # 기존 의존성들...
     
     # 수동으로 추가
     supabase_services:
       path: ./supabase_services
     flutter_dotenv: ^5.1.0
   
   # assets 섹션에 .env 파일 추가
   flutter:
     assets:
       - .env
   ```

4. `main.dart` 파일 수정:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:supabase_services/supabase_services.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Initialize Supabase services
     await SupabaseServices.initialize();
     
     runApp(const MyApp());
   }
   
   // 나머지 앱 코드...
   ```

## 3. Supabase 자격 증명 설정

`.env` 파일을 편집하여 Supabase URL과 익명 키를 입력합니다:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 4. 의존성 가져오기

새 프로젝트에서 다음 명령어를 실행하여 의존성을 가져옵니다:

```bash
flutter pub get
```

## 5. 서비스 패키지 사용하기

Supabase 기능을 사용하려면 다음 단계를 따르세요:

### 인증

```dart
final supabaseService = SupabaseServices.supabaseService;

// 익명 로그인
final token = await supabaseService.signInAnonymously();
```

### 이미지 업로드

```dart
final result = await supabaseService.uploadUserImage(
  imageBytes,  // Uint8List
  'image/jpeg', // 컨텐츠 타입
  authToken     // 인증 토큰
);

// 업로드된 이미지 URL 가져오기
final imageUrl = result['image']['image_url'];
```

### 프리셋 이미지 목록 가져오기

```dart
// 모든 프리셋 이미지 가져오기
final presets = await supabaseService.getPresetImages();

// 카테고리별 프리셋 이미지 가져오기
final traditionalPresets = await supabaseService.getPresetImages(category: 'traditional');
```

### 이미지 생성 기능 사용하기

```dart
final inferenceService = SupabaseServices.inferenceService;

// 이미지 생성 요청
final result = await inferenceService.generateHanbokFitting(
  sourcePath: sourceImageUrl, // 사용자 이미지 URL
  targetPath: presetImageUrl, // 프리셋 이미지 URL
);

// 결과가 null이면 작업이 처리 중이므로 폴링 필요
if (result == null) {
  // 최신 작업 ID 가져오기
  final taskId = inferenceService.taskIds.last;
  
  // 주기적으로 결과 확인
  void pollForResults() async {
    final status = await inferenceService.checkTaskStatus(taskId);
    
    if (status['status'] == 'completed') {
      final resultUrl = status['image_url'];
      // 결과 URL 사용
      print('이미지 생성 완료: $resultUrl');
    } else if (status['status'] == 'error') {
      print('에러: ${status['error_message']}');
    } else {
      // 아직 처리 중이므로 3초 후 다시 확인
      Future.delayed(const Duration(seconds: 3), pollForResults);
    }
  }
  
  // 폴링 시작
  pollForResults();
}
```

## 6. 상태 관리 통합하기

자신의 애플리케이션에 맞는 상태 관리 클래스를 만들어 보세요:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';

class MyAppState extends ChangeNotifier {
  final _supabaseService = SupabaseServices.supabaseService;
  final _inferenceService = SupabaseServices.inferenceService;
  
  bool _isLoading = false;
  String? _authToken;
  List<HanbokImage> _presets = [];
  String? _resultImageUrl;
  
  bool get isLoading => _isLoading;
  String? get authToken => _authToken;
  List<HanbokImage> get presets => _presets;
  String? get resultImageUrl => _resultImageUrl;
  
  // 초기화 및 인증
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 익명 로그인
      _authToken = await _supabaseService.signInAnonymously();
      
      // 프리셋 가져오기
      _presets = await _supabaseService.getPresetImages();
    } catch (e) {
      print('초기화 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 애플리케이션별 메서드 추가...
}
```

## 7. Edge Function 확인

서비스 패키지는 다음과 같은 특정 Edge Function을 사용합니다:

1. `upload-user-image` - 사용자 이미지 업로드
2. `get-presets` - 프리셋 이미지 가져오기
3. `generate-hanbok-image` - 한복 가상 피팅 결과 생성
4. `check-status` - 작업 상태 확인

Supabase 프로젝트에 이러한 Edge Function이 제대로 배포되어 있는지 확인하세요.

## 문제 해결

- **인증 문제**: Supabase URL과 익명 키가 올바른지 확인
- **Edge Function 오류**: Edge Function이 제대로 배포되었는지 확인
- **이미지 업로드 실패**: Supabase의 저장소 버킷 권한 확인

## 추가 리소스

- `supabase_services/example_usage.dart` 파일에서 전체 사용 예시 확인
- 각 서비스 파일의 API 문서에서 사용 가능한 모든 메서드에 대한 자세한 정보 확인
- `supabase_services/INTEGRATION.md` 파일에서 통합 가이드 확인 