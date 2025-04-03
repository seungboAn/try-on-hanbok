import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_responsive.dart';

/// 앱 전체에서 사용하는 텍스트 스타일 상수를 관리하는 클래스
class AppTextStyles {
  AppTextStyles._(); // 인스턴스화 방지를 위한 private 생성자

  // 기본 폰트 패밀리
  static const String _fontFamily = 'Pretendard';
  static const String _timesFontFamily = 'Times';

  // 각 디바이스 타입별 텍스트 스타일 설정 메서드
  static TextStyle _getResponsiveStyle({
    required BuildContext context,
    required double mobileFontSize,
    required double tabletFontSize,
    required double desktopFontSize,
    String? fontFamily,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    final bool isMobile = AppResponsive.isMobile(context);
    final bool isTablet = AppResponsive.isTablet(context);

    // 디바이스 타입에 따른 폰트 크기 조정
    double fontSize =
        isMobile
            ? mobileFontSize
            : isTablet
            ? tabletFontSize
            : desktopFontSize;

    return TextStyle(
      fontFamily: fontFamily ?? _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  // 전체 텍스트 테마 가져오기
  static TextTheme getTextTheme() {
    return GoogleFonts.notoSansKrTextTheme().copyWith(
      displayLarge: GoogleFonts.notoSansKr(
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: GoogleFonts.notoSansKr(
        fontSize: 30,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.notoSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // 앱바 타이틀 스타일 (화면 맨 상단)
  static TextStyle appBarTitle(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 16,
      tabletFontSize: 18,
      desktopFontSize: 20,
      fontFamily: _timesFontFamily,
      fontWeight: FontWeight.normal,
      letterSpacing: 3,
    );
  }

  // 헤드라인 스타일 (큰 제목)
  static TextStyle headline1(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 32,
      tabletFontSize: 40,
      desktopFontSize: 48,
      fontFamily: _timesFontFamily,
      fontWeight: FontWeight.normal,
      height: 1.2,
    );
  }

  static TextStyle headline2(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 24,
      tabletFontSize: 28,
      desktopFontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.3,
    );
  }

  static TextStyle headline3(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 20,
      tabletFontSize: 22,
      desktopFontSize: 24,
      fontWeight: FontWeight.bold,
      height: 1.4,
    );
  }

  // 본문 스타일
  static TextStyle body1(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 16,
      tabletFontSize: 17,
      desktopFontSize: 18,
      height: 1.5,
    );
  }

  static TextStyle body2(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 14,
      tabletFontSize: 15,
      desktopFontSize: 16,
      color: AppColors.textSecondary,
      height: 1.6,
    );
  }

  // 버튼 텍스트 스타일
  static TextStyle button(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 14,
      tabletFontSize: 15,
      desktopFontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textButton,
      letterSpacing: 0.5,
    );
  }

  // 필터 버튼 텍스트 스타일
  static TextStyle filterButton(
    BuildContext context, {
    required bool isActive,
  }) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 14,
      tabletFontSize: 15,
      desktopFontSize: 16,
      fontWeight: FontWeight.w500,
      color:
          isActive ? AppColors.filterTextActive : AppColors.filterTextInactive,
    );
  }

  // 캡션 스타일 (작은 텍스트)
  static TextStyle caption(BuildContext context) {
    return _getResponsiveStyle(
      context: context,
      mobileFontSize: 12,
      tabletFontSize: 12,
      desktopFontSize: 13,
      color: AppColors.textSecondary,
      height: 1.4,
    );
  }
}
