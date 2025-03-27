import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF6A4C93); // Purple color used for highlights
  static const Color secondaryColor = Color(0xFFF4F4F4); // Light gray for backgrounds
  static const Color accentColor = Color(0xFF8C52FF); // Brighter purple for accents
  static const Color textColor = Color(0xFF333333); // Dark gray for text
  static const Color borderColor = Color(0xFFDDDDDD); // Light gray for borders
  static const Color backgroundColor = Colors.white; // White for main background
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    color: textColor,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  
  // Padding and spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Border radius
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
} 