import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// 앱의 반응형 설정을 관리하는 클래스
class AppResponsive {
  AppResponsive._(); // 인스턴스화 방지를 위한 private 생성자

  // 모바일/태블릿/데스크탑 구분을 위한 픽셀 값
  static const double mobileMaxWidth = 650;
  static const double tabletMinWidth = 651;
  static const double tabletMaxWidth = 1100;
  static const double desktopMinWidth = 1101;
  static const double desktopMaxWidth = 1440;
  static const double largeScreenMinWidth = 1441;

  // 반응형 브레이크포인트 정의
  static List<Breakpoint> get breakpoints => [
    const Breakpoint(start: 0, end: mobileMaxWidth, name: MOBILE),
    const Breakpoint(start: tabletMinWidth, end: tabletMaxWidth, name: TABLET),
    const Breakpoint(
      start: desktopMinWidth,
      end: desktopMaxWidth,
      name: DESKTOP,
    ),
    const Breakpoint(
      start: largeScreenMinWidth,
      end: double.infinity,
      name: '4K',
    ),
  ];

  // 반응형 빌더 래퍼
  static Widget responsiveBuilder(BuildContext context, Widget? child) {
    return ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: breakpoints,
    );
  }

  // 디바이스 타입 확인 메서드들
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).smallerThan(TABLET);
  }

  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET) &&
        ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
  }

  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).largerThan(TABLET);
  }
}
