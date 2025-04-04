import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수를 관리하는 클래스
class AppColors {
  AppColors._(); // 인스턴스화 방지를 위한 private 생성자

  //Color(0xFF9B64F6); // 주 색상 (퍼플)
  //Color(0xFF56CDC0); // 보조 색상 (청록)
  //Color(0xFFB68DF8); // 주 색상 밝은 버전
  //Color(0xFFFFC300); // 강조 색상 (노랑)
  //Color(0xFFE53935); // 오류 색상 (빨강)

  // 기본 색상
  static const Color primary = Color(0xFF56CDC0); // 보조 색상 (청록)
  static const Color primaryLight = Color(0xFFA8E6CF); // 주 색상 밝은 버전
  static const Color secondary = Color(0xFF87A96B); // 세이지 그린
  static const Color accent = Color(0xFFFFD3AC); // 강조 색상 (연 복숭아색)
  static const Color error = Color(0xFFE53935); // 오류 색상 (빨강)

  // 배경 색상
  static const Color background = Colors.white;
  static const Color backgroundLight = Color(0xFFF3F3F3); // 연한 회색 배경
  static const Color backgroundMedium = Color(0xFFE1E1E1); // 중간 회색 배경
  static const Color backgroundDark = Color(0xFFE0E0E0);
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color modalBackground = Color(0xFFF9F9F9);

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF212121); // 기본 텍스트
  static const Color textSecondary = Color(0xFF757575); // 부제목/설명 텍스트
  static const Color textHint = Color(0xFFBDBDBD); // 힌트 텍스트
  static const Color textButton = Color(0xFF0055CC); // 버튼 텍스트

  // 경계선 색상
  static const Color border = Color(0xFFDDDDDD);
  static const Color divider = Color(0xFFEEEEEE);

  // 상태 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // 버튼 상태 색상
  static const Color buttonActive = primary;
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonHover = Color(0xFFF5F5F5);

  // 이미지 테두리 색상
  static const Color imageStroke = primary;
  static const Color imageStrokeHover = primaryLight;

  // 필터 버튼 색상
  static const Color filterButtonActive = primary;
  static const Color filterButtonInactive = Color(0xFFEEEEEE);
  static const Color filterTextActive = Colors.white;
  static const Color filterTextInactive = textSecondary;

  // 그림자 색상
  static Color shadowColor = Colors.black.withOpacity(0.1);

  // 버튼 색상
  static const Color buttonPrimary = Color(0xFF007AFF);
}
