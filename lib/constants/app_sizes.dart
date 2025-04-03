import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'app_responsive.dart';
import 'app_constants.dart';

/// 앱 전체에서 사용하는 사이즈 상수를 관리하는 클래스
class AppSizes {
  AppSizes._(); // 인스턴스화 방지를 위한 private 생성자

  // 기기 타입 정의 - AppResponsive 클래스의 상수 활용
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppResponsive.mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppResponsive.tabletMinWidth &&
      MediaQuery.of(context).size.width < AppResponsive.tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppResponsive.desktopMinWidth;

  // 화면 크기에 따른 컨테이너 최대 너비
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width;
    if (isTablet(context)) return 650;
    return 1200; // 데스크탑
  }

  // 섹션별 패딩
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 40);
    }
  }

  // 섹션간 간격
  static double getSectionSpacing(BuildContext context) {
    if (isMobile(context)) return 40;
    if (isTablet(context)) return 60;
    return 80; // 데스크탑
  }

  // 기존 메소드들을 모두 가져오고 사이즈별로 정리
  // 헤더와 섹션 사이 간격
  static double getHeaderBottomPadding(BuildContext context) {
    if (isMobile(context)) return 0;
    if (isTablet(context)) return 0;
    return 0; // 데스크탑
  }

  // 섹션1과 섹션2 사이 간격
  static double getSection1BottomPadding(BuildContext context) {
    if (isMobile(context)) return 40;
    if (isTablet(context)) return 80;
    return 100; // 데스크탑
  }

  // 섹션2와 섹션3 사이 간격
  static double getSection2BottomPadding(BuildContext context) {
    if (isMobile(context)) return 40;
    if (isTablet(context)) return 80;
    return 100; // 데스크탑
  }

  // Try On 버튼 위 패딩
  static double getTryOnButtonTopPadding(BuildContext context) {
    if (isMobile(context)) return 10;
    if (isTablet(context)) return 15;
    return 20; // 데스크탑
  }

  // 버튼 크기
  static double getButtonWidth(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.homeButtonWidthMobile;
    } else {
      return AppConstants.homeButtonWidthDesktop;
    }
  }

  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.homeButtonHeightMobile;
    } else {
      return AppConstants.homeButtonHeightDesktop;
    }
  }

  // 이미지 관련 사이즈
  static double getImageCardRadius() => 12.0;
  static double getHanbokPreviewHeight(BuildContext context) {
    if (isMobile(context)) return 400;
    if (isTablet(context)) return 500;
    return 600; // 데스크탑
  }

  // 프리셋 이미지 크기
  static double getPresetImageSize(BuildContext context) {
    if (isMobile(context)) return AppConstants.imagePresetSizeMobile;
    if (isTablet(context)) return AppConstants.imagePresetSizeTablet;
    return AppConstants.imagePresetSize; // 데스크탑
  }

  // 업로드 버튼 크기
  static double getUploadButtonSize(BuildContext context) {
    if (isMobile(context)) return AppConstants.uploadButtonSizeMobile;
    if (isTablet(context)) return AppConstants.uploadButtonSizeTablet;
    return AppConstants.uploadButtonSize; // 데스크탑
  }

  // 하단 여백
  static double getFooterPadding(BuildContext context) {
    if (isMobile(context)) return 40;
    if (isTablet(context)) return 60;
    return 80; // 데스크탑
  }
}
