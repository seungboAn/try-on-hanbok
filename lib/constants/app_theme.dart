import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체 테마를 관리하는 클래스
class AppTheme {
  AppTheme._(); // 인스턴스화 방지를 위한 private 생성자

  // 앱 전체 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      primaryColorLight: AppColors.primaryLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        background: AppColors.background,
        error: AppColors.error,
      ),

      // 앱바 테마
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textButton,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // 텍스트 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // 카드 테마
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),

      // 다이얼로그 테마
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.background,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // UI 요소 공통 스타일 정의

  // 그림자 스타일
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // 이미지 스타일 (한복 이미지 표시용)
  static BoxDecoration imageBoxDecoration({bool isHovered = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isHovered ? AppColors.imageStrokeHover : AppColors.imageStroke,
        width: isHovered ? 2 : 1,
      ),
    );
  }

  // 버튼 스타일 (Try On 버튼 등)
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textButton,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // 필터 버튼 스타일
  static ButtonStyle filterButtonStyle({required bool isActive}) {
    return ElevatedButton.styleFrom(
      backgroundColor:
          isActive
              ? AppColors.filterButtonActive
              : AppColors.filterButtonInactive,
      foregroundColor:
          isActive ? AppColors.filterTextActive : AppColors.filterTextInactive,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
