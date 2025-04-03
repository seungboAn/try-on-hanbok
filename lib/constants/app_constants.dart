/// 앱 전체에서 사용하는 상수들을 관리하는 클래스
class AppConstants {
  AppConstants._(); // 인스턴스화 방지를 위한 private 생성자

  // 앱 정보
  static const String appName = 'Try On Hanbok';
  static const String appDescription = '가상 한복 피팅 서비스';
  static const String appVersion = '1.0.0';

  // 이미지 경로
  static const String imagePath = 'assets/images/';
  static const String modernImagePath = 'assets/images/modern/';
  static const String traditionalImagePath = 'assets/images/traditional/';
  static const String logoImagePath = 'assets/images/logo.png';
  static const String uploadPlaceholderPath =
      'assets/images/upload_placeholder.png';
  static const String resultBackgroundPath =
      'assets/images/result_background.png';
  static const String resultImagePath = 'assets/images/result_image.png';

  // 한복 이미지 리스트 (모던)
  static const List<String> modernHanbokList = [
    'assets/images/modern/modern_001.png',
    'assets/images/modern/modern_002.png',
    'assets/images/modern/modern_003.png',
    'assets/images/modern/modern_004.png',
    'assets/images/modern/modern_005.png',
    'assets/images/modern/modern_006.png',
    'assets/images/modern/modern_007.png',
    'assets/images/modern/modern_008.png',
  ];

  // 한복 이미지 리스트 (전통)
  static const List<String> traditionalHanbokList = [
    'assets/images/traditional/traditional_001.png',
    'assets/images/traditional/traditional_002.png',
    'assets/images/traditional/traditional_003.png',
    'assets/images/traditional/traditional_004.png',
    'assets/images/traditional/traditional_005.png',
    'assets/images/traditional/traditional_006.png',
    'assets/images/traditional/traditional_007.png',
    'assets/images/traditional/traditional_008.png',
  ];

  // 필터 타입
  static const String filterModern = 'Modern';
  static const String filterTraditional = 'Traditional';

  // 애니메이션 지속 시간
  static const Duration defaultAnimationDuration = Duration(milliseconds: 100);
  static const Duration pageTransitionDuration = Duration(milliseconds: 200);

  // 라우팅 경로
  static const String homeRoute = '/';
  static const String generateRoute = '/generate';
  static const String resultRoute = '/result';

  // UI 요소 상수
  static const double defaultBorderRadius = 12.0;
  static const double defaultButtonBorderRadius = 8.0;
  static const double defaultCardBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;

  // 테두리 두께 상수
  static const double borderWidthThin = 0.2;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthMedium = 1.2;
  static const double borderWidthThick = 1.5;
  static const double borderWidthHover = 2.4;

  // 이미지 관련 상수
  static const double imagePresetSize = 120.0;
  static const double imagePresetSizeTablet = 100.0;
  static const double imagePresetSizeMobile = 80.0;

  static const double uploadButtonSize = 120.0;
  static const double uploadButtonSizeTablet = 100.0;
  static const double uploadButtonSizeMobile = 60.0;

  static const double imageBorderRadius = 20.0;

  // 간격 상수
  static const double spacingSmall = 8.0;
  static const double spacingNormal = 12.0;
  static const double spacingMedium = 20.0;
  static const double spacingLarge = 40.0;

  // 튜토리얼 섹션 관련 상수
  static const String tutorialTitle = 'How to Try On Hanbok?';
  static const String tutorialStep1Title = 'Step 1. Upload Your Photo';
  static const String tutorialStep1Description =
      'Upload your photo to preview yourself in hanbok.';
  static const String tutorialStep1Image = 'assets/images/tutorial_image1.png';
  static const String tutorialStep2Title = 'Step 2. Select Hanbok';
  static const String tutorialStep2Description =
      'Choose your favorite hanbok from our collection.';
  static const String tutorialStep2Image = 'assets/images/tutorial_image2.png';
  static const String tutorialStep3Title = 'Step 3. Generate Result';
  static const String tutorialStep3Description =
      'Get the result image with just one click.';
  static const String tutorialStep3Image = 'assets/images/tutorial_image3.png';
  static const String tutorialButtonText = 'Try On Start';
  static const String tutorialFooter =
      'Experience the beauty of Korean traditional attire in seconds.';

  // 기타 상수
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB

  // 버튼 관련 상수
  static const double filterButtonWidth = 100.0;
  static const double filterButtonHeight = 40.0;
  static const double moreButtonWidth = 150.0;
  static const double moreButtonHeight = 40.0;

  // 버튼 관련 상수
  static const double buttonHoverElevation = 4.0;

  // 홈 버튼 크기
  static const double homeButtonWidthDesktop = 180.0;
  static const double homeButtonHeightDesktop = 48.0;
  static const double homeButtonWidthMobile = 140.0;
  static const double homeButtonHeightMobile = 40.0;
}
